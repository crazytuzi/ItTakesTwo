import Vino.Pickups.PlayerPickupComponent;

class UMiniatureAmplifierCapability : UHazeCapability
{
	AHazePlayerCharacter Player;
	AHazeActor FaceActor;

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 1;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (GetAttributeObject(n"AplifierFacing") != nullptr && 
		HasControl() &&
		IsActioning(ActionNames::Cancel) &&
		UPlayerPickupComponent::Get(Player).IsHoldingObject())
		{
			return EHazeNetworkActivation::ActivateLocal;
		}
        	
		else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UObject Obj = GetAttributeObject(n"AplifierFacing");
		
		FaceActor = Cast<AHazeActor>(Obj);
		FVector LookDirection = FaceActor.ActorLocation - Player.ActorLocation;
		LookDirection *= -1;

		FVector PlayerFaceDirection = Player.ActorForwardVector;

		float DotToForward = PlayerFaceDirection.DotProduct(LookDirection.GetSafeNormal());
		Player.SetActorRotation(FRotator::MakeFromX(LookDirection.GetSafeNormal()));
	}
}