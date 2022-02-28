import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonBaboonBoss;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonBaboonLaserCircle;

class UMoonBaboonSlamFollowCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::MovementAction);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AMoonBaboonBoss MoonBaboon;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MoonBaboon = Cast<AMoonBaboonBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (MoonBaboon.bFollowPlayerForSlam)
			return EHazeNetworkActivation::ActivateFromControl;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoonBaboon.bFollowPlayerForSlam)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
    void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
    {
		
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MoonBaboon.HazeAkComp.HazePostEvent(MoonBaboon.UfoSlamBoostStartEvent);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{	
		MoonBaboon.HazeAkComp.HazePostEvent(MoonBaboon.UfoGroundSlamStartEvent);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		bool bIsMayDead = Game::GetMay().IsPlayerDead();
		FVector TargetLocation = Game::GetMay().ActorLocation;
		if (bIsMayDead)
			TargetLocation = MoonBaboon.FloorActor.ActorLocation;

		TargetLocation.Z = MoonBaboon.FloorActor.ActorLocation.Z + MoonBaboon.OffsetFromGround;

		FVector CurLoc = FMath::VInterpConstantTo(Owner.ActorLocation, TargetLocation, DeltaTime, 5000.f);
		CurLoc.Z = MoonBaboon.FloorActor.ActorLocation.Z + MoonBaboon.OffsetFromGround;
		Owner.SetActorLocation(CurLoc);

		if (bIsMayDead)
			return;

		FVector Dif = Owner.ActorLocation - Game::GetMay().ActorLocation;
		Dif.Z = 0.f;

		if (Dif.IsNearlyZero(200.f) && HasControl())
		{
			MoonBaboon.PerformSlam();
		}
	}
}