
class UClockworkStayInScreenCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"StayInScreen");

	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
	
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 101;

	AHazePlayerCharacter Player;
	FVector2D ScreenPos = FVector2D::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        // return EHazeNetworkActivation::ActivateFromControl;
        return EHazeNetworkActivation::ActivateLocal;
        // return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// return EHazeNetworkDeactivation::DeactivateFromControl;
		// return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		
		SceneView::ProjectWorldToViewpointRelativePosition(Game::GetMay(), Player.ActorLocation, ScreenPos);
		Print(""+ScreenPos);
		Print(""+GetAttributeVector(AttributeVectorNames::MovementDirection));
		if(ScreenPos.X < 0.05)
		{
			float ClampedY = FMath::Clamp(GetAttributeVector(AttributeVectorNames::MovementDirection).Y, -1.f, 0.f); 
			float ClampedX = GetAttributeVector(AttributeVectorNames::MovementDirection).X;
			Player.SetCapabilityAttributeVector(AttributeVectorNames::MovementDirection, FVector(ClampedX, ClampedY, 0.f));
		}
		if(ScreenPos.X > 0.95)
		{
			float ClampedY = FMath::Clamp(GetAttributeVector(AttributeVectorNames::MovementDirection).Y, 0.f, 1.f); 
			float ClampedX = GetAttributeVector(AttributeVectorNames::MovementDirection).X;
			Player.SetCapabilityAttributeVector(AttributeVectorNames::MovementDirection, FVector(ClampedX, ClampedY, 0.f));
			Print("Hello");
		}
	}

	
}