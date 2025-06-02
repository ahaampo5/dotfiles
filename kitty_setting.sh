if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install kitty
elif [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case $ID in
        ubuntu|debian)
            sudo apt update
            sudo apt install -y kitty
            ;;
        fedora|centos|rhel)
            if command -v dnf &> /dev/null; then
                sudo dnf install -y kitty
            else
                sudo yum install -y kitty
            fi
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm kitty
            ;;
        *)
            echo "지원되지 않는 Linux 배포판: $ID"
            echo "수동으로 kitty를 설치해주세요."
            return 1
            ;;
    esac
else
    echo "OS를 감지할 수 없습니다."
    return 1
fi
# kitty 설정 파일 생성
mkdir -p ~/.config/kitty
if [[ ! -f ~/.config/kitty/kitty.conf ]]; then
    touch ~/.config/kitty/kitty.conf
fi
# kitty 설정 파일에 기본 설정 추가
cat <<EOL >> ~/.config/kitty/kitty.conf
# 기본 설정
font_family      MesloLGS NF
font_size        13.0
use_gpu          yes
background_opacity 0.92
blur_radius        5.0
color_scheme     Dracula
map command+t new_tab
map command+w close_tab
map command+shift+t new_window
map command+shift+w close_window
EOL
# kitty 설정 파일에 추가적인 설정
cat <<EOL > ~/.config/kitty/kitty.conf
# 추가 설정
# 탭바 숨기기
hide_tab_bar yes
# 탭바 위치
tab_bar_position top
# 탭바 색상
tab_bar_background_color #282a36
# 탭바 글꼴 색상
tab_bar_foreground_color #f8f8f2
# 탭바 활성화된 탭 색상
active_tab_background_color #44475a
active_tab_foreground_color #f8f8f2
# 탭바 비활성화된 탭 색상
inactive_tab_background_color #282a36
inactive_tab_foreground_color #6272a4
# 탭바 활성화된 탭 테두리 색상
active_tab_border_color #bd93f9
# 탭바 비활성화된 탭 테두리 색상
inactive_tab_border_color #44475a
# 탭바 활성화된 탭 글꼴 두께
active_tab_font_weight bold
# 탭바 비활성화된 탭 글꼴 두께
inactive_tab_font_weight normal
# 탭바 활성화된 탭 글꼴 크기
active_tab_font_size 13.0
# 탭바 비활성화된 탭 글꼴 크기
inactive_tab_font_size 13.0
# 탭바 활성화된 탭 글꼴 스타일
active_tab_font_style normal
# 탭바 비활성화된 탭 글꼴 스타일
inactive_tab_font_style normal
# 탭바 활성화된 탭 글꼴 패밀리
active_tab_font_family MesloLGS NF
# 탭바 비활성화된 탭 글꼴 패밀리
inactive_tab_font_family MesloLGS NF
# 탭바 활성화된 탭 글꼴 색상
active_tab_font_color #f8f8f2
# 탭바 비활성화된 탭 글꼴 색상
inactive_tab_font_color #6272a4
EOL
# kitty 설정 파일에 추가적인 단축키 설정
cat <<EOL >> ~/.config/kitty/kitty.conf
# 단축키 설정
map ctrl+shift+t new_tab
map ctrl+shift+w close_tab
map ctrl+shift+n new_window
map ctrl+shift+q close_window
map command+c copy_to_clipboard
map command+v paste_from_clipboard
map cmd+1 goto_tab 1
map cmd+2 goto_tab 2
map cmd+3 goto_tab 3
map cmd+4 goto_tab 4
# 스크롤백 설정
scrollback_lines 10000
# 마우스 스크롤 설정
mouse_scroll_on_paste yes
# 마우스 클릭 설정
mouse_hide_when_typing yes
# 마우스 커서 설정
mouse_cursor_shape beam
# 마우스 커서 색상
mouse_cursor_color #f8f8f2
# 마우스 커서 크기
mouse_cursor_size 1.0
# 마우스 커서 두께
mouse_cursor_thickness 2.0
EOL

echo "alias diff='kitten diff'" >> ~/.zshrc
echo "alias icat='kitten icat'" >> ~/.zshrc

echo "if [ -x \"\$(command -v neofetch)\" ]; then" >> ~/.zshrc
echo "  neofetch --stdout" >> ~/.zshrc
echo "fi" >> ~/.zshrc
echo "echo \"*******************************\"" >> ~/.zshrc
echo "echo \"   Welcome, \$(whoami)! \$(date +\"%Y-%m-%d %H:%M:%S\")\"" >> ~/.zshrc
echo "echo \"*******************************\"" >> ~/.zshrc

echo "kitty 설정이 완료되었습니다. ~/.config/kitty/kitty.conf 파일을 확인해주세요."