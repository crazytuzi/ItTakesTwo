import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;

class UMusicFlyingInputCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"MusicalFlyingInput");
	
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 1;

	AHazePlayerCharacter Player;
	UMusicalFlyingComponent FlyingComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		FlyingComp = UMusicalFlyingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(!FlyingComp.IsInputEnabled())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector Input = GetAttributeVector(AttributeVectorNames::MovementRaw);
		const FVector Forward = Player.ViewRotation.ForwardVector * Input.X;
		const FVector Right = Player.ViewRotation.RightVector * Input.Y;
		const FVector ProjectedDirection = (Forward + Right);
		FlyingComp.TurnInput = GetAttributeVector(AttributeVectorNames::MovementDirection);
		FlyingComp.MovementRaw = GetAttributeVector(AttributeVectorNames::MovementRaw);
		FlyingComp.InputMovementPlane += ProjectedDirection;
		FlyingComp.InputMovementPlane.Normalize();
		FlyingComp.bWantsToDoLoop = false;

		if(FlyingComp.bMoveUpDownWithButtons)
		{
			if(IsActioning(ActionNames::MusicHoverDown))
			{
				FlyingComp.VerticalInput = -1;
			}
			else if(IsActioning(ActionNames::MusicHoverUp))
			{
				FlyingComp.VerticalInput = 1;
			}
			else
			{
				FlyingComp.VerticalInput = 0;
			}
		}

		//System::DrawDebugArrow(Owner.ActorLocation, Owner.ActorLocation + ProjectedDirection * 2000, 10, FLinearColor::Red);

		FlyingComp.bWantsToFly = WasActionStarted(ActionNames::MusicFlyingStart);
		FlyingComp.bWantsToStopFlying = IsActioning(ActionNames::Cancel);
		if(WasActionStarted(ActionNames::MovementGrindGrapple))
		{
			FlyingComp.bWantsToDoLoop = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!FlyingComp.IsInputEnabled())
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FlyingComp.InputMovementPlane = FVector::ZeroVector;
		FlyingComp.TurnInput = FVector::ZeroVector;
		FlyingComp.MovementRaw = FVector::ZeroVector;
		FlyingComp.VerticalInput = 0.0f;
		FlyingComp.bWantsToFly = false;
	}
}
