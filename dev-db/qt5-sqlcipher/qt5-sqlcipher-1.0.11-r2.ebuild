# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="Qt SQL driver plugin for SQLCipher"
HOMEPAGE="https://github.com/blizzard4591/qt5-sqlcipher"
SRC_URI="https://github.com/blizzard4591/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="LGPL-2.1" # version 2.1 only
SLOT="0"
KEYWORDS="~amd64"

RDEPEND=">=dev-db/sqlcipher-3.4.1
	>=dev-qt/qtcore-5.15.16:5=
	>=dev-qt/qtsql-5.15.16:5=[sqlite] <dev-qt/qtsql-5.16:5=[sqlite]"
DEPEND="${RDEPEND}"

DOCS=(README.md)

src_prepare() {
	eapply "${FILESDIR}"/${PN}-1.0.10-install-path.patch
	cp -a "${S}"/qt-file-cache/5.15.{0,16} || die
	eapply "${FILESDIR}"/${P}-qt-5.15.16.patch
	sed -i -e "s/@LIBDIR@/$(get_libdir)/" CMakeLists.txt || die

	local v=$(best_version dev-qt/qtsql:5)
	v=$(ver_cut 1-3 ${v#*/qtsql-})
	[[ -n ${v} ]] || die "could not determine qtsql version"
	if ! [[ -d qt-file-cache/${v} ]]; then
		local vc
		case $(ver_cut 1-2 ${v}) in
			5.15) vc=5.15.16 ;;
			*) die "qtsql-${v} not supported" ;;
		esac
		elog "qtsql-${v} not in cache, using ${vc} instead"
		cp -R qt-file-cache/${vc} qt-file-cache/${v} || die
	fi

	cmake_src_prepare
}

src_test() {
	cd "${BUILD_DIR}" || die
	./qsqlcipher-test || die
}
