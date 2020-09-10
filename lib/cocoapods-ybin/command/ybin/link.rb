module Pod
  class Command
    class Ybin < Command
      class Link < Ybin

        autoload :Analyzer,                     'cocoapods/installer/analyzer'
        self.summary = '二进制库源码映射工具'

        self.description = <<-DESC
          二进制库源码映射工具.
        DESC

        self.arguments = [
              CLAide::Argument.new('LIB_NAME', false)
        ]
        def self.options
          [
            ['--list', '查询所有已映射源码库'],
            ['--remove', '删除源码映射(多个空格隔开)'],
            ['--remove-all', '删除所有源码映射'],
            ['--lib-version', '查询 Podfile 所有依赖库的版本']
          ]
        end

        def initialize(argv)
          # @name = argv.shift_argument

          @names = argv.arguments! unless argv.arguments.empty?
          @list = argv.flag?('list', false)
          @link = argv.flag?('link', false)
          @remove = argv.flag?('remove', false)
          @remove_all = argv.flag?('remove-all', false)
          @lib_version = argv.flag?('lib-version', false)

          @config = Pod::Config.instance
          super
        end

        def validate!
          super
          # help! 'A Pod option is required.' unless @name
          banner! if @help
        end

        def run

          if @link && @list && @remove && @remove_all && @lib_version
            UI.puts "[Error] 请选择合适的命令, 不支持同时多个Option\n".red
            help!
            return
          end

          if @list
            analyzerPodFileLock
            linked_list
          elsif @remove
            analyzerPodFileLock
            linked_remove
          elsif @remove_all
            analyzerPodFileLock
            linked_remove_all
          elsif @lib_version
            analyzerPodFileLock
            read_podfile_lock_version
          elsif @names
            analyzerPodFileLock
            linkLibSource
          else
            help!
          end
        end

        # 映射源码
        def linkLibSource

          if @names.nil?
            UI.puts "[Error] 请输入需要映射的组件库. 示例: $ pod ybin link foo\n".red
            return
          else
            if @names.count > 1
              UI.puts "[Error] 不支持一次映射多个源码. 示例: $ pod ybin link foo\n".red
              return
            end
          end

          user_lib_name = @names.first.chomp.strip
          lib_version = get_lib_version(user_lib_name)
          if lib_version == nil || lib_version == ""
            print "\n[!]Podfile 无法获取".yellow " #{user_lib_name} ".green "版本号, 但仍支持源码映射\n".yellow
          else

            is_contain_lib = linked_list_contain(user_lib_name)
            if is_contain_lib
              print "\n[Error] #{user_lib_name} 已映射 (#{lib_version}), 如需重新映射，请先删除\n\n".red
              return
            else
              print "\n#{project_name} Using ".green "#{user_lib_name} (#{lib_version})\n".green
            end
          end

          config = config_with_asker
          lib_path = config["libPath"]
          sourcePath = config["sourcePath"]
          lib_name = source_lib_name(lib_path)

          lib_real_path = ""
          if Pathname.new(lib_path).extname == ".framework"
            lib_real_path = "#{lib_path}/#{lib_name}"
          elsif Pathname.new(lib_path).extname == ".a"
            lib_real_path = lib_path
          end

          if lib_real_path == "" || !File.exist?(lib_real_path)
            UI.puts "\n[Error] 二进制文件不存在, 请检查文件位置!\n".red
            return
          end

          if sourcePath == "" || !File.exist?(sourcePath)
            UI.puts "\n[Error] 源码文件不存在, 请检查文件位置!\n".red
            return
          end

          link_source_code(lib_real_path, sourcePath, lib_name)
        end

        def link_source_code(lib_path, sourcePath, lib_name)

          comp_dir_path = `dwarfdump "#{lib_path}" | grep "AT_comp_dir" | head -1 | cut -d \\" -f2`
          if comp_dir_path == nil || comp_dir_path == ""
            UI.puts "\n[Error] #{lib_name} 不支持映射源码\n".red
            return
          end

          lib_debug_path = comp_dir_path.chomp.strip
          if File.exist?(lib_debug_path) || File.directory?(lib_debug_path)
            if File.symlink?(lib_debug_path)
              print "源码映射已存在, 无法重复映射，请删除后重新映射: #{lib_debug_path}"
            else
              print "源码映射目录已存在, 请检查 #{lib_debug_path} 目录(可能存在以下情况):"
              UI.puts "\n1、开发源码(无需映射，即可调试) \n2、其他重复文件, 请手动移动/移除\n".red
            end
          else

            begin
              FileUtils.mkdir_p(lib_debug_path)
            rescue SystemCallError
              array = lib_debug_path.split('/')
              if array.length > 3
                root_path = '/' + array[1] + '/' + array[2]
                unless File.exist?(root_path)
                  UI.puts "[Error] 无权限创建文件夹，请手动创建#{root_path}文件夹，再重试\n".red
                end
              end
            end

            FileUtils.rm_rf(lib_debug_path)
            File.symlink(sourcePath, lib_debug_path)
            check_linked(lib_path, lib_debug_path, lib_name)
          end
        end

        def check_linked(lib_path, sourcePath, lib_name)

          source_path = `dwarfdump "#{lib_path}" | grep -E "DW_AT_decl_file.*#{lib_name}.*\\.m|\\.c" | head -1 | cut -d \\" -f2`
          source_path = source_path.chomp.strip
          if File.exist?(source_path)
            UI.puts "🍺🍺🍺 Successfully! 源码映射成功\n".green
            recordLinknSuccessLib(lib_name, lib_path, sourcePath)
          else
            UI.puts "[Error] 源码 #{source_path} 不存在, 请检查源码版本 或 存储位置\n".red
          end
        end

        # 移除单个映射
        def linked_remove
          if @names.nil?
            UI.puts "[Error] 请输入要删除的组件库. 实例: $ pod ybin --remove xxx yyy zzz\n".red
            return
          end

          @names.each do  |name|

            lib_linked_path = get_lib_linked_path(name)
            if lib_linked_path.nil? || lib_linked_path == ""
              UI.puts "[Error] #{name} 的映射不存在, 无需移除".red
            else
              if File.exist?(lib_linked_path) && File.symlink?(lib_linked_path)
                FileUtils.rm_rf(lib_linked_path)
                removeLinkedFileRecord(name)
                UI.puts "#{name} 成功移除".green
              else
                UI.puts "[Error] #{name} 的映射不存在, 请手动核查: #{lib_linked_path}".red
              end
            end
          end
          print "\n"
        end

        # 移除所有映射
        def linked_remove_all

          if File.exist?(source_record_file_path)
            records = JSON.parse(File.read(source_record_file_path))

            if records.count > 0
              records.each.with_index(0) do |record, index|
                lib_linked_path = record["source_path"]
                lib_name = record["lib_name"]
                if File.exist?(lib_linked_path) && File.symlink?(lib_linked_path)
                  FileUtils.rm_rf(lib_linked_path)
                  removeLinkedFileRecord(lib_name)
                  UI.puts "#{lib_name} removing...".green
                end
              end
              UI.puts "\n已全部移除\n".green
            else
              UI.puts "\n无记录\n".green
            end
          end
        end

        # 查询映射列表
        def linked_list

          if File.exist?(source_record_file_path)
            records = JSON.parse(File.read(source_record_file_path))
            if records.count > 0
              records.each.with_index(1) do |record, index|
                lib_version_s = record["lib_version"]
                lib_version_s = (lib_version_s == nil || lib_version_s == '') ? "" : "(#{lib_version_s})"
                UI.puts "#{index}. #{record["lib_name"]} #{lib_version_s} ".green "Source: #{record["source_path"]}".yellow
              end
            else
              UI.puts "\n无记录".green
            end
          else
            UI.puts "\n无记录".green
          end
          print "\n"
        end

        private


        def linked_list_contain(lib_name)

          is_contain_lib = false
          if File.exist?(source_record_file_path)
            records = JSON.parse(File.read(source_record_file_path))
            records.each.with_index(1) do |record, index|
              if record["lib_name"] == lib_name
                is_contain_lib = true
                break
              end
            end
          end
          is_contain_lib
        end

        def source_root
          cache_root_dir_name = ".ybin"
          user_home_path = Dir.home
          cache_root_path = File.join(user_home_path, cache_root_dir_name);
          FileUtils.mkdir_p(cache_root_path) unless File.exist? cache_root_path
          cache_root_path
        end

        def source_record_file_path
          source_r_path = File.join(source_root.to_s, 'ybin_source_links.json')
          source_r_path
        end

        def source_lib_name(filePath)
          file_name = ""
          if Pathname.new(filePath).extname == ".framework"
            file_name = File.basename(filePath, ".framework")
          elsif Pathname.new(filePath).extname == ".a"
            file_name = File.basename(filePath, ".a")
            file_name = file_name[3..file_name.length]
          end
          file_name
        end

        def project_name
          targets = @aggregate_targets.map(&:user_project_path).compact.uniq
          project_name = ""
          if targets.count == 1
            project_name = targets.first.basename('.xcodeproj')
          end
          project_name
        end

        def recordLinknSuccessLib(lib_name, lib_path, sourcePath)

          if File.exist?(source_record_file_path)
            record = JSON.parse(File.read(source_record_file_path))

            record_libNames = Array.new
            record.each do |sub|
              record_libNames.push(sub['lib_name'])
            end

            if record_libNames.include?(lib_name)

              replace_index = record_libNames.index(lib_name)
              record[replace_index] = generate_record_item(lib_name, lib_path, sourcePath)
              record_item_json = JSON.generate(record)

              FileUtils.rm_rf(source_record_file_path) if File.exist?(source_record_file_path)
              File.open(source_record_file_path, 'w') { |file| file.write(record_item_json)}
            else

              record.push(generate_record_item(lib_name, lib_path, sourcePath))
              record_item_json = JSON.generate(record)

              FileUtils.rm_rf(source_record_file_path) if File.exist?(source_record_file_path)
              File.open(source_record_file_path, 'w') { |file| file.write(record_item_json)}
            end
          else
            record_items = Array.new
            record_items.push(generate_record_item(lib_name, lib_path, sourcePath))
            record_item_json = JSON.generate(record_items)
            File.open(source_record_file_path, 'w') { |file| file.write(record_item_json)}
          end
        end

        def generate_record_item(lib_name, lib_path, source_path)
          lib_version = get_lib_version(lib_name.chomp.strip)
          record_item = {:lib_name => lib_name, :lib_version => lib_version, :lib_path => lib_path, :source_path => source_path}
          record_item
        end

        def removeLinkedFileRecord(lib_name)

          if File.exist?(source_record_file_path)
            records = JSON.parse(File.read(source_record_file_path))

            lib_name_index = -1
            records.each.with_index(0) do |record, index|
              if record["lib_name"] == lib_name
                lib_name_index = index
                break
              end
            end

            if lib_name_index >= 0
              records.delete_at(lib_name_index)
              record_item_json = JSON.generate(records)

              FileUtils.rm_rf(source_record_file_path) if File.exist?(source_record_file_path)
              File.open(source_record_file_path, 'w') { |file| file.write(record_item_json)}
            end
          end
        end

        def analyzerPodFileLock

          podfile_lock = File.join(Pathname.pwd, "Podfile.lock")
          if File.exist?(podfile_lock)
          else
            UI.puts "\n[!] 未匹配到 Podfile.lock 文件, 无法获取 Pod 管理信息\n".red
            return
          end
          @lockfile ||= Lockfile.from_file(Pathname.new(podfile_lock))

          UI.section "ybin analyzer" do
            analyzer = Pod::Installer::Analyzer.new(config.sandbox, config.podfile, @lockfile)
            @analysis_result = analyzer.analyze
            @aggregate_targets = @analysis_result.targets
            @pod_targets = @analysis_result.pod_targets
          end
        end

        def read_podfile_lock_version
          if @analysis_result.nil?
            return
          end

          UI.section "#{project_name} 通过 Cocoapods 管理的依赖库(含 dependency)版本:".yellow do
            root_specs = @analysis_result.specifications.map(&:root).uniq
            pods_to_install = @analysis_result.sandbox_state.added | @analysis_result.sandbox_state.changed
            root_specs.sort_by(&:name).each.with_index(1) do |spec, index|
              if pods_to_install.include?(spec.name)
              else
                UI.puts "#{index}. #{spec}".green
              end
            end
            print "\n"
          end
        end

        def get_lib_version(lib_name)
          if @analysis_result.nil?
            return
          end

          lib_version = ''
          root_specs = @analysis_result.specifications.map(&:root).uniq
          pods_to_install = @analysis_result.sandbox_state.added | @analysis_result.sandbox_state.changed
          root_specs.sort_by(&:name).each.with_index(1) do |spec, index|
            if pods_to_install.include?(spec.name)
            else
              if spec.name == lib_name
                lib_version = spec.version
                break
              end
            end
          end
          lib_version
        end

        def get_lib_linked_path(lib_name)

          lib_linked_path = ""
          if File.exist?(source_record_file_path)
            records = JSON.parse(File.read(source_record_file_path))
            records.each do |record|
              if record["lib_name"] == lib_name
                lib_linked_path = record["source_path"]
                break
              end
            end
          end
          lib_linked_path
        end

        def template_source
          {
            'libPath' => { question: '1/2 请输入静态二进制库的路径(如：/Users/xxx/Workspace/xxx.a 或 /Users/xxx/Workspace/xxx.framework)' },
            'sourcePath' => { question: '2/2 源码路径(注意: 版本是否匹配)' },
          }
        end

        def config_with_asker
          config = {}
          template_source.each do |k, v|
            config[k] = get_require_path(v[:question])
          end
          print "\n"
          config
        end

        def get_require_path(question)

          Pod::UI.puts "\n#{question}".yellow
          answer = ''
          loop do
            print "->".green
            answer = STDIN.gets.chomp.strip
            next if answer.empty?
            break
          end
          answer
        end

      end
    end
  end
end
