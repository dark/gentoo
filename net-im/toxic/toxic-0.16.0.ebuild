# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..13} )

inherit python-single-r1 xdg

DESCRIPTION="A curses-based client for Tox"
HOMEPAGE="https://github.com/JFreegman/toxic"
SRC_URI="https://github.com/JFreegman/toxic/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="+audio-notify debug experimental games llvm notification png python qrcode +sound +video +X"
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )
	video? ( sound X ) "

BDEPEND="virtual/pkgconfig"

RDEPEND="dev-libs/libconfig:=
	>=net-libs/tox-0.2.19:=
	net-misc/curl
	sys-kernel/linux-headers
	sys-libs/ncurses:=
	audio-notify? (
		media-libs/freealut
		media-libs/openal
	)
	debug? ( llvm? ( llvm-core/llvm:* ) )
	experimental? ( net-libs/tox[experimental] )
	notification? ( x11-libs/libnotify )
	python? ( ${PYTHON_DEPS} )
	qrcode? (
		media-gfx/qrencode:=
		png? ( media-libs/libpng )
	)
	sound? (
		media-libs/openal
		net-libs/tox:=[av]
	)
	video? (
		media-libs/libvpx:=
		net-libs/tox:=[av]
	)
	X? (
		x11-base/xorg-proto
		x11-libs/libX11
	)"

DEPEND="${RDEPEND}"

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

src_prepare() {
	default
	#prevent man files from being compressed.
	sed -i -e "/gzip/d" cfg/targets/install.mk || die "Unable to prevent compression of man pages."
	#Fix incorrect linkage of pthread (may be optional)
	sed -i -e 's/pthread/lpthread/g' Makefile || die "Unable to fix linking of pthread."
	#Makefile sets some required CFLAGS only if CFLAGS variable is undefined,
	#This line changes the "lazy set if absent" assignment to a "lazy set" assignment.
	#look below in src_configure to see how CFLAGS are passed to the makefile in USER_CFLAGS
	sed -i -e 's/?=/=/g' Makefile || die "Unable to change assignment of CFLAGS and LDFLAGS"
	#Fix incomplete invocation of python-config
	sed -i -e "s/--ldflags/--ldflags --embed/" cfg/checks/python.mk || die "Unable to fix python linking"
}

src_configure() {
	if ! use audio-notify; then
		export DISABLE_SOUND_NOTIFY=1
	fi
	if use debug; then
		export ENABLE_RELEASE=0
		if use llvm; then
			export ENABLE_ASAN=1
		fi
	fi
	if use experimental; then
		export ENABLE_TOX_EXPERIMENTAL=1
	fi
	if ! use games; then
		export DISABLE_GAMES=1
	fi
	if ! use notification; then
		export DISABLE_DESKTOP_NOTIFY=1
	fi
	if ! use png; then
		export DISABLE_QRPNG=1
	fi
	if use python; then
		export ENABLE_PYTHON=1
	fi
	if ! use qrcode; then
		export DISABLE_QRCODE=1
	fi
	if ! use sound; then
		export DISABLE_AV=1
	fi
	if ! use video; then
		export DISABLE_VI=1
	fi
	if ! use X; then
		export DISABLE_X11=1
	fi
	#Including strings.h fixes undefined reference to strcasecmp()
	#Including linux/limits.h fixes undefinded reference to NAME_MAX and PATH_MAX macros
	#Defining _GNU_SOURCE fixes undefined reference to strcasestr()
	export USER_CFLAGS="${CFLAGS} -include strings.h -include linux/limits.h -D _GNU_SOURCE"
	export USER_LDFLAGS="${LDFLAGS}"
	#set install directory to /usr.
	sed -i -e "s,/usr/local,${EPREFIX}/usr,g" cfg/global_vars.mk || die "Failed to set install directory!"
}

src_install() {
	default
	if ! use audio-notify; then
		rm -r "${ED}"/usr/share/${PN}/sounds || die "Could not remove sounds directory"
	fi
}

pkg_postinst() {
	xdg_desktop_database_update
	einfo	"An example config file has been installed at /usr/share/toxic/toxic.conf.example"
	einfo	"Feel free to copy it to ~/.config/tox/toxic.conf and modify as desired"
}
