import Vino.Time.ActorTimeDilationStatics;
import Vino.Movement.Components.MovementComponent;
import Vino.PlayerHealth.PlayerHealthStatics;

/* 
	Used during the explosion gameplay in Clockwork Last boss.
*/

class UClockworkLastBossMayExplosionCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ClockworkLastBossMayExplosionCapability");

	default CapabilityDebugCategory = n"ClockworkLastBossMayExplosionCapability";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	float TimeDilationValue = 0.f;
	float LeftInputClamped = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (Player.IsPlayerDead())
			return EHazeNetworkActivation::DontActivate;

		if (Player != Game::GetMay())
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Player.IsPlayerDead())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (Player != Game::GetMay())
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ClearActorTimeDilation(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		// Setting the Time Dilation on May from 0.4 to 0.5 based on the players stick Input
		// No stick input = slowest time dilation 
		FVector2D LeftInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
		LeftInputClamped = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.f), FVector2D(0.4f, 0.5f), LeftInput.Size());
		TimeDilationValue = FMath::FInterpTo(TimeDilationValue, LeftInputClamped, DeltaTime, 10.f);
		ModifyActorTimeDilation(Player, LeftInputClamped, this, false);
	}
}