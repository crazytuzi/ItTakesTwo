import Vino.Pickups.PlayerPickupComponent;
/*
	Icon used on a microphone that will display if the user is holding a miniature amplifier
*/

class UUAmplifierActivationPointCapability : UHazeCapability
{
	AHazePlayerCharacter Player;
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.QueryActivationPoints(UAmplifierActivationPoint::StaticClass());
		Player.UpdateActivationPointAndWidgets(UAmplifierActivationPoint::StaticClass());
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}
}

class UAmplifierActivationPoint : UHazeActivationPoint
{
	default ValidationType = EHazeActivationPointActivatorType::Cody;
	
	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const
	{
		UPlayerPickupComponent PickupComponent = UPlayerPickupComponent::Get(Player);

		if(PickupComponent.IsHoldingObject())
		{
			return EHazeActivationPointStatusType::Valid;
		}

		return EHazeActivationPointStatusType::InvalidAndHidden;
	}
}
