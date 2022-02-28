import Cake.LevelSpecific.Music.LevelMechanics.Classic.FollowCloud.FollowCloudSettings;
import Cake.LevelSpecific.Music.LevelMechanics.Classic.FollowCloud.FollowCloudRepulsor;

class UFollowCloudAvoidanceCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default TickGroup = ECapabilityTickGroups::GamePlay;

	UFollowCloudSettings Settings;
	UHazeAITeam Team;
	UFollowCloudRepulsorComponent OwnComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Settings = UFollowCloudSettings::GetSettings(Owner);
		Team = Owner.JoinTeam(FollowCloudAvoidance::TeamName);
		OwnComp = UFollowCloudRepulsorComponent::Get(Owner);
		ensure((Settings != nullptr) && (Team != nullptr) && (OwnComp != nullptr));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Team.Members.Num() < 2)
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Team.Members.Num() < 2)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		TSet<AHazeActor> Repulsors = Team.GetMembers();
		for (AHazeActor Repulsor : Repulsors)
		{
			if ((Repulsor == nullptr) || (Repulsor == Owner))
				continue;

			UFollowCloudRepulsorComponent RepulseComp = UFollowCloudRepulsorComponent::Get(Repulsor);
			if (RepulseComp == nullptr)
				return;

			if (!RepulseComp.CanRepulse(OwnComp.WorldLocation))
				continue;
			
			Owner.AddImpulse(RepulseComp.GetRepulsionForce(OwnComp.WorldLocation));
		}
	}
}
