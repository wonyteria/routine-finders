path = 'app/views/personal_routines/_club_routines.html.erb'
content = File.read(path, encoding: 'UTF-8')
content.gsub!(/border-dashed /, "")
content.gsub!(/personal_routines_path\(tab: "free"\)/, 'personal_routines_path(tab: "free", focus_new: true)')
File.write(path, content, encoding: 'UTF-8')
