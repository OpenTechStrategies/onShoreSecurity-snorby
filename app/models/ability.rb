class Ability
  include CanCan::Ability

  def initialize(user)
    if user.admin
      can :manage, :all
    else
      permission(user, Sensor.root)
    end

  end

  def permission(user, sensor)
    (user.roles & sensor.roles).sort{|r1, r2| r2.permission <=> r1.permission }.each do |role|
      case role.permission.to_sym
      when :none
        cannot :manage, sensor.all_childs(true)
      else
        cannot :manage, sensor.all_childs(true)
        can role.permission.to_sym, sensor.all_childs(true, true)
      end
    end

    sensor.childs.select{|s1| s1.domain}.each{|s2| permission(user, s2)}

  end

end
