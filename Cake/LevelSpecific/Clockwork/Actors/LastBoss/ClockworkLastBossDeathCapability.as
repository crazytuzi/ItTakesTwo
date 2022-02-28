import Vino.Movement.Components.MovementComponent;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.ClockworkLastBossDeathComponent;
class UClockworkLastBossDeathCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ClockworkLastBossDeathCapability");
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"ClockworkLastBossDeathCapability";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UClockworkLastBossDeathComponent Comp;

	FVector FallLocation = FVector::ZeroVector;
	float FallHeight = 0.f;
	
	bool bHasStampedHeight = false;
	bool bShouldCheckHeight = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Player);
		Comp = UClockworkLastBossDeathComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IsActioning(n"ClockDeath"))
			return EHazeNetworkActivation::DontActivate;

	    return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsActioning(n"ClockDeath"))
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!HasControl())
			return;

		if (MoveComp.IsAirborne() && !Player.IsPlayerDead())
			StampHeightOnAirborne();

		CheckHeight();
	}

	void CheckHeight()
	{
		if (bShouldCheckHeight)
		{
			FallHeight = FallLocation.Z - Player.GetActorLocation().Z;
			
			if (!MoveComp.IsAirborne())
				StopCheckingHeight();

			if (FallHeight > Comp.FallHeightToDeath)
			{
				KillPlayer(Player);
				StopCheckingHeight();
			}
		}
	}

	void StampHeightOnAirborne()
	{
		if(bHasStampedHeight)
			return;

		bHasStampedHeight = true;
		bShouldCheckHeight = true;
		FallLocation = Player.GetActorLocation();
	}

	void StopCheckingHeight()
	{
		bShouldCheckHeight = false;
		bHasStampedHeight = false;
	}
}