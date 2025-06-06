# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

if [[ ${PV} == *9999* ]]; then
	EGIT_REPO_URI="https://anongit.freedesktop.org/git/libreoffice/libcdr.git"
	inherit autotools git-r3
else
	SRC_URI="https://dev-www.libreoffice.org/src/libcdr/${P}.tar.xz"
	KEYWORDS="~amd64 ~arm ~arm64 ~hppa ~loong ~ppc ~ppc64 ~riscv ~sparc ~x86"
	inherit libtool
fi

DESCRIPTION="Library parsing the Corel cdr documents"
HOMEPAGE="https://wiki.documentfoundation.org/DLP/Libraries/libcdr"

LICENSE="MPL-2.0"
SLOT="0"
IUSE="doc test"

RESTRICT="!test? ( test )"

RDEPEND="
	>=dev-libs/icu-75:=
	dev-libs/librevenge
	media-libs/lcms:2
	sys-libs/zlib
"
DEPEND="${RDEPEND}
	dev-libs/boost
"
BDEPEND="
	dev-build/libtool
	virtual/pkgconfig
	doc? ( app-text/doxygen )
	test? ( dev-util/cppunit )
"

src_prepare() {
	default
	[[ -d m4 ]] || mkdir "m4"
	if [[ ${PV} == *9999* ]]; then
		eautoreconf
	else
		elibtoolize
	fi
}

src_configure() {
	local myeconfargs=(
		$(use_with doc docs)
		$(use_enable test tests)
	)
	econf "${myeconfargs[@]}"
}

src_install() {
	default
	find "${D}" -name '*.la' -delete || die
}
