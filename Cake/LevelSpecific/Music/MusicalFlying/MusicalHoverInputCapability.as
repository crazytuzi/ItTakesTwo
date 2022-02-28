import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;

UCLASS(Deprecated)
class UMusicalHoverInputCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"MusicalHoverInput");
	
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = -10;

	UMusicalFlyingComponent FlyingComp;
	AHazePlayerCharacter Player;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		FlyingComp = UMusicalFlyingComponent::Get(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
		{
			return EHazeNetworkActivation::DontActivate;
		}

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FlyingComp.HoverMovementDirection = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//FlyingComp.HoverMovementDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
		FVector DirectionInputUpDown = GetAttributeVector(AttributeVectorNames::LeftStickRaw);

		if(DirectionInputUpDown.X > KINDA_SMALL_NUMBER)
		{
			FlyingComp.HoverMovementDirection = Player.GetActorRightVector() * FMath::Abs(DirectionInputUpDown.X * 1.35f);
		}
		else if(DirectionInputUpDown.X < -KINDA_SMALL_NUMBER)
		{
			FlyingComp.HoverMovementDirection = -Player.GetActorRightVector() * FMath::Abs(DirectionInputUpDown.X * 1.35f);
		}
		else
		{
			FlyingComp.HoverMovementDirection = FVector::ZeroVector;
		}

	
		if(DirectionInputUpDown.Y > KINDA_SMALL_NUMBER)
		{
			FlyingComp.HoverMovementDirection.Z = Player.GetMovementWorldUp().Z * FMath::Abs(DirectionInputUpDown.Y * 1.05f);
		}
		else if(DirectionInputUpDown.Y < -KINDA_SMALL_NUMBER)
		{
			FlyingComp.HoverMovementDirection.Z = -Player.GetMovementWorldUp().Z * FMath::Abs(DirectionInputUpDown.Y * 1.45f);
		}
		else
		{
			FlyingComp.HoverMovementDirection.Z = 0;
		}

		





	//	FVector DirectionInputX = GetAttributeVector(AttributeVectorNames::MovementDirection);
	//	FlyingComp.HoverMovementDirection.X = DirectionInputX.X;
	// 	FVector DirectionInputY = GetAttributeVector(AttributeVectorNames::MovementDirection);
	//	FlyingComp.HoverMovementDirection.Y = DirectionInputY.Y;
	

	//	PrintToScreen("DirectionInputZ" + DirectionInputUpDown.Y);
	//	PrintToScreen("DirectionInputX" + DirectionInputX.X);
	//	PrintToScreen("DirectionInputY" + DirectionInputY.Y);

		if(Player.IsSteeringPitchInverted())
		{
			//FlyingComp.HoverMovementDirection.Z = -DirectionInput.Y;
		}
		
		else
		{	
			//FlyingComp.HoverMovementDirection.Z = DirectionInput.Y;
		}
		

	

		
	//	FlyingComp.HoverMovementDirection.X = DirectionInput.X;
		
		
		/*
		if(IsActioning(ActionNames::MusicHoverUp))
		{
			FlyingComp.HoverMovementDirection.Z = 1.0f;
		}
		else if(IsActioning(ActionNames::MusicHoverDown))
		{
			FlyingComp.HoverMovementDirection.Z = -1.0f;
		}
		else
		{
			FlyingComp.HoverMovementDirection.Z = 0.f;
		}
		*/
	}
}
