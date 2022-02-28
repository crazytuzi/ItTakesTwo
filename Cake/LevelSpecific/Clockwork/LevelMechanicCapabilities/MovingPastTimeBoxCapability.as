import Cake.LevelSpecific.Clockwork.Actors.PortalRoom.RotatingLever;

class UMovingPastTimeBoxCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	bool bStop = false;

	AHazePlayerCharacter Player;
	AHazeActor Box;
	AStaticMeshActor PresentBox;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (Box != nullptr)
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bStop)
		    return EHazeNetworkDeactivation::DeactivateFromControl;

        return EHazeNetworkDeactivation::DontDeactivate;

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(n"Movement", this);
		Box.AttachToActor(Player, n"Root", EAttachmentRule::KeepWorld);
		PresentBox.AttachToActor(Player, n"Root", EAttachmentRule::KeepWorld);

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Box.DetachFromActor(EDetachmentRule::KeepWorld);
		PresentBox.DetachFromActor(EDetachmentRule::KeepWorld);
		Box = nullptr;
		Player.UnblockCapabilities(n"Movement", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		UObject BoxObject;
		if (ConsumeAttribute(n"PastTimeBox", BoxObject))
		{
			Box = Cast<AHazeActor>(BoxObject);
		}

		UObject PresentBoxObject;
		if (ConsumeAttribute(n"PresentTimeBox", PresentBoxObject))
		{
			PresentBox = Cast<AStaticMeshActor>(PresentBoxObject);
		}
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		
		FVector LeftStickVector = GetAttributeVector(AttributeVectorNames::LeftStickRaw);

		FVector NewLoc;
		FVector YMove = Player.CurrentlyUsedCamera.ForwardVector.ConstrainToPlane(Player.MovementWorldUp) * ((LeftStickVector.Y * 400.f) * DeltaTime);
		FVector XMove = Player.CurrentlyUsedCamera.RightVector.ConstrainToPlane(Player.MovementWorldUp) * ((LeftStickVector.X * 400.f) * DeltaTime);
		NewLoc = Player.ActorLocation + YMove + XMove;
		Player.SetActorLocation(NewLoc);
		
		if (IsActioning(ActionNames::Cancel))
		{
			bStop = true;
		}
			
	}

}