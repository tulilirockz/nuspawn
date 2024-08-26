Name:          nuspawn
Vendor:        tulilirockz
Version:       0.9.0+{{{ git_ref }}}
Release:       0%{?dist}
Summary:       Helper for Nspawn and Machinectl
License:       BSD-3-Clause
URL:           https://github.com/%{vendor}/%{name}
VCS:           {{{ git_dir_vcs }}}
Source:        {{{ git_dir_pack }}}

BuildArch:     noarch 
Supplements:   systemd
BuildRequires: scdoc
Requires:      nu

%description
Wraps systemd-nspawn for fetching and easier usage

%global debug_package %{nil}
%global pname nuspawn

%prep
{{{ git_dir_setup_macro }}}

%build

%install
mkdir -p %{buildroot}%{_libexecdir}/%{pname} %{buildroot}/%{_bindir}
sed -i 's/\%GIT_COMMIT\%/{{ git_ref }}/g' src/lib/meta.nu
sed -i 's/\%VERSION\%/%{VERSION}/g' src/lib/meta.nu
sed -i 's~\.\/lib~\/usr\/share/%{pname}~' src/%{pname}
install -D -m 0755 src/%{pname} %{buildroot}%{_bindir}/%{pname}
cp -r src/lib/* %{buildroot}%{_libexecdir}/%{pname}
cp -r docs/man/* %{buildroot}/share/man
cp LICENSE %{buildroot}/share/licenses/%{pname}

%files
%license LICENSE
/usr/share/%{name}/*
%attr(0755,root,root) %{_bindir}/%{pname}

%changelog
%autochangelog
