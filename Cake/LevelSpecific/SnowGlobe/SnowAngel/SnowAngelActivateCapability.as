import Cake.LevelSpecific.SnowGlobe.SnowAngel.PlayerSnowAngelComponent;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.SnowAngel.SnowAngelSnowFolk;
import Cake.LevelSpecific.SnowGlobe.SnowAngel.SnowAngelDyingSnowFolk;

class USnowAngelActivateCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SnowAngelDive");

	default CapabilityDebugCategory = n"Gameplay";	
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UHazeMovementComponent MoveComp;

	const float StartDelay = 0.2f;

	FVector SnowMoundLocation;
	FVector StartLocation;

	TArray<APlayerController> PlayerControllerArray;

	APlayerController PlayerControllerRef;

	UPlayerSnowAngelComponent PlayerSnowAngelComponent;

	float RelativeZOffset = 400.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		PlayerSnowAngelComponent = UPlayerSnowAngelComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::InteractionTrigger))
		    return EHazeNetworkActivation::DontActivate;

		ASnowAngelSnowFolk SnowFolk = Cast<ASnowAngelSnowFolk>(MoveComp.DownHit.Actor);

		if (SnowFolk != nullptr)
		    return EHazeNetworkActivation::DontActivate;

		ASnowAngelDyingSnowFolk SnowFolkDying = Cast<ASnowAngelDyingSnowFolk>(MoveComp.DownHit.Actor);

		if (SnowFolkDying != nullptr)
		    return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ActiveDuration < StartDelay)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (!PlayerSnowAngelComponent.bHasActivated)
			PlayerSnowAngelComponent.bHasActivated = true;

		if (PlayerSnowAngelComponent == nullptr)
			return;

		PlayerSnowAngelComponent.RightAxisValue = 0.f;
		PlayerSnowAngelComponent.bCanExit = false;
		PlayerSnowAngelComponent.HideAngelPrompt(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerSnowAngelComponent.bIsActive = true;
	}
}