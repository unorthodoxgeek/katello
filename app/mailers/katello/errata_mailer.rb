module Katello
  class ErrataMailer < ApplicationMailer
    helper :'katello/errata_mailer'

    def host_errata(options)
      user = ::User.find(options[:user])
      @content_hosts = Katello::System.authorized_as(user, :view_content_hosts).reject { |host| host.applicable_errata.empty? }

      set_locale_for(user) do
        mail(:to => user.mail, :subject => _("Satellite Host Advisory"))
      end
    end

    def sync_errata(options)
      user = options[:user]

      all_errata = options[:errata]
      @repo = options[:repo]
      @errata_counts = errata_counts(all_errata)
      @errata = all_errata.take(100).group_by(&:errata_type)

      set_locale_for(user) do
        mail(:to => user.mail, :subject => (_("Satellite Sync Summary for %s") % @repo.name))
      end
    end

    def promote_errata(options)
      user = options[:user]

      @content_view = options[:content_view]
      @environment = options[:environment]
      @content_hosts = Katello::System.where(:environment_id => @environment.id, :content_view_id => @content_view.id).authorized_as(user, :view_content_hosts)
      @errata = @content_hosts.map(&:installable_errata).flatten.uniq

      set_locale_for(user) do
        mail(:to => user.mail, :subject => (_("Satellite Promotion Summary for %{content_view}") % {:content_view => @content_view.name}))
      end
    end

    private

    def errata_counts(errata)
      counts = {:total => errata.count}
      counts.merge(Hash[[:security, :bugfix, :enhancement].collect do |errata_type|
        [errata_type, errata.send(errata_type).count]
      end])
    end
  end
end
