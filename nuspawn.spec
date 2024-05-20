Name:          nuspawn
Vendor:        tulilirockz
Version:       0.3.0+{{{ git_ref }}}
Release:       0%{?dist}
Summary:       Helper for Nspawn and Machinectl
License:       3.0-BSD
URL:           https://github.com/%{vendor}/%{name}
VCS:           {{{ git_dir_vcs }}}
Source:        {{{ git_dir_pack }}}

BuildArch:     noarch 
Supplements:   systemd
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
sed -i 's~\.\/lib~\/usr\/libexec/%{pname}~' src/%{pname}
install -D -m 0755 src/%{pname} %{buildroot}%{_bindir}/%{pname}
cp -r src/lib/* %{buildroot}%{_libexecdir}/%{pname}

%files
%license LICENSE
%{_libexecdir}/%{name}/*
%attr(0755,root,root) %{_bindir}/%{pname}

%changelog
%autochangelog
