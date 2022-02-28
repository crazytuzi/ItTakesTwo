import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleCannon;
import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleCannonShooterComponent;

class UCastleCannonUserCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"Cannon";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UCastleCannonShooterComponent ShooterComponent;

	ACastleCannon Cannon;
	USceneComponent CameraPivot;

	FVector MuzzleDirection;
	FVector CameraForwardVector;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ShooterComponent = UCastleCannonShooterComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (ShooterComponent.ActiveCannon == nullptr)
        	return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ShooterComponent.ActiveCannon != Cannon)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Cannon = ShooterComponent.ActiveCannon;	

		Player.AttachToComponent(Cannon.ShooterAttach);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Cannon = nullptr;

		Player.DetachRootComponentFromParent(true);

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	

		
	}
}
