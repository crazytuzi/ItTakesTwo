import Peanuts.Triggers.HazeTriggerBase;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

event void FBothPlayerTriggerEvent();

enum EBothPlayerTriggerHandshakeControlSide
{
	WorldControl,
	May,
	Cody
}

/**
 * Trigger volume that triggers when both players
 * enter the volume, and un-triggers when either
 * player then leaves it again.
 */
UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking", ComponentWrapperClass)
class ABothPlayerTrigger : AVolume
{
    // If checked, delegates on this trigger will be completely independent in network.
    UPROPERTY(BlueprintReadOnly, Category = "Trigger", meta = (EditCondition = "!bTriggerUsingHandshake"))
   	protected bool bTriggerLocally = false;

	// We can setup a handshake to validate that both players are actually inside the trigger
	// This will add a waiting sheet for the player that is waiting for the handshake.
	UPROPERTY(BlueprintReadOnly, Category = "Trigger", meta = (EditCondition = "!bTriggerLocally"))
    protected bool bTriggerUsingHandshake = false;

	UPROPERTY(Category = "Trigger", meta = (EditCondition = "bTriggerUsingHandshake", EditConditionHides))
	protected EBothPlayerTriggerHandshakeControlSide HandshakeControlSide = EBothPlayerTriggerHandshakeControlSide::WorldControl;
	
	// If no capablity is added, the default 'BothPlayerTriggerIdleCapability' is added
	UPROPERTY(Category = "Trigger", meta = (EditCondition = "bTriggerUsingHandshake", EditConditionHides))
	protected TSubclassOf<UHazeCapability> OptionalHandshakeIdleCapablity;

	UPROPERTY(Category = "Trigger")
	FBothPlayerTriggerEvent OnBothPlayersInside;

	UPROPERTY(Category = "Trigger")
	FBothPlayerTriggerEvent OnStopBothPlayersInside;

	private TPerPlayer<bool> IsPlayerInside;
	private bool bBothInside = false;

    default bGenerateOverlapEventsDuringLevelStreaming = false;

	private AHazePlayerCharacter SheetedPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// We manually update player overlaps on beginplay,
		// this avoids an expensive UpdateOverlaps call by allowing
		// us to set bGenerateOverlapEventsDuringLevelStreaming to false.
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Trace::ComponentOverlapComponent(BrushComponent, Player.CapsuleComponent))
				BrushComponent.ManualInsertRealComponentOverlap(Player.CapsuleComponent);
		}
	}

    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (bTriggerLocally)
		{
			IsPlayerInside[Player] = true;
			UpdateBothInside();
		}
		else
		{
			if (!Player.HasControl())
				return;
			NetSetPlayerIsInside(Player, true);
		}
    }

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (bTriggerLocally)
		{
			IsPlayerInside[Player] = false;
			UpdateBothInside();
		}
		else
		{
			if (!Player.HasControl())
				return;
			NetSetPlayerIsInside(Player, false);
		}
    }

	private void UpdateBothInside()
	{
		ensure(HasControl() || bTriggerLocally || bTriggerUsingHandshake);

		const bool bShouldBoth = (IsPlayerInside[0] && IsPlayerInside[1]);
		if (bShouldBoth && !bBothInside)
		{		
			if (bTriggerLocally || !Network::IsNetworked())
			{
				bBothInside = true;	
				OnBothPlayersInside.Broadcast();
			}
			else if(!bTriggerUsingHandshake)
			{
				bBothInside = true;	
				NetBroadcastInsideEvent(true);
			}
			else if(SheetedPlayer == nullptr)
			{
				InitalizeHandshake();
			}
		}
		else if (!bShouldBoth && bBothInside)
		{		
			bBothInside = false;
			if (bTriggerLocally || !Network::IsNetworked())
				OnStopBothPlayersInside.Broadcast();
			else if(!bTriggerUsingHandshake)
				NetBroadcastInsideEvent(false);
			else if(SheetedPlayer == nullptr)
				OnStopBothPlayersInside.Broadcast();		
		}
	}

	UFUNCTION(NetFunction)
	private void NetAddHandshakeCapability(AHazePlayerCharacter Player, FVector Location)
	{
		SheetedPlayer = Player;
		Player.SetCapabilityAttributeObject(n"Trigger", this);

		if(!OptionalHandshakeIdleCapablity.IsValid())
			Player.AddCapability(UBothPlayerTriggerIdleCapability::StaticClass());
		else
			Player.AddCapability(OptionalHandshakeIdleCapablity);	
	}

	private void RemoveHandshakeCapablity(AHazePlayerCharacter Player)
	{
		if(!OptionalHandshakeIdleCapablity.IsValid())
			Player.RemoveCapability(UBothPlayerTriggerIdleCapability::StaticClass());
		else
			Player.RemoveCapability(OptionalHandshakeIdleCapablity);	
	}

	private void InitalizeHandshake()
	{
		if(HandshakeControlSide == EBothPlayerTriggerHandshakeControlSide::WorldControl && HasControl())
		{
			for(auto Player : Game::GetPlayers())
			{
				if(!Player.HasControl())
					continue;

				// Add the idle sheet while we are waiting for the answer
				NetAddHandshakeCapability(Player, Player.GetActorLocation());						
			}

			NetSendHandshakeRequest();
		}
		else if(HandshakeControlSide == EBothPlayerTriggerHandshakeControlSide::May && Game::May.HasControl())
		{
			NetAddHandshakeCapability(Game::May, Game::May.GetActorLocation());		
			NetSendHandshakeRequest();
		}
		else if(HandshakeControlSide == EBothPlayerTriggerHandshakeControlSide::Cody && Game::Cody.HasControl())
		{
			NetAddHandshakeCapability(Game::Cody, Game::Cody.GetActorLocation());
			NetSendHandshakeRequest();
		}
	}

	UFUNCTION(NetFunction)
	private void NetSendHandshakeRequest()
	{
		const bool bShouldBoth = (IsPlayerInside[0] && IsPlayerInside[1]);
		if(HandshakeControlSide == EBothPlayerTriggerHandshakeControlSide::WorldControl && !HasControl())
		{
			NetSendHandshakeAnswer(bShouldBoth);
		}
		else if(HandshakeControlSide == EBothPlayerTriggerHandshakeControlSide::May && !Game::May.HasControl())
		{
			NetSendHandshakeAnswer(bShouldBoth);
		}
		else if(HandshakeControlSide == EBothPlayerTriggerHandshakeControlSide::Cody && !Game::Cody.HasControl())
		{
			NetSendHandshakeAnswer(bShouldBoth);
		}
	}

	UFUNCTION(NetFunction)
	private void NetSendHandshakeAnswer(bool bBothIsideOnBothSides)
	{
		if(SheetedPlayer != nullptr)
		{
			RemoveHandshakeCapablity(SheetedPlayer);
			SheetedPlayer = nullptr;
		}

		if(bBothIsideOnBothSides)
		{
			// Make sure the players are still inside the volume
			for(auto Player : Game::GetPlayers())
			{
				FVector LocationInsideShape = Player.GetActorLocation();
				BrushComponent.GetClosestPointOnCollision(LocationInsideShape, LocationInsideShape);

				if(!LocationInsideShape.Equals(Player.GetActorLocation()))
				{
					if(!Player.HasControl())
						Player.CleanupCurrentMovementTrail();

					Player.SetActorLocation(LocationInsideShape);
				}				
			}
		
			bBothInside = true;
			OnBothPlayersInside.Broadcast();
		}
		else
		{
			// while we where waiting for the answer
			// the player might have come back
			UpdateBothInside();
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetSetPlayerIsInside(AHazePlayerCharacter Player, bool bInside)
	{
		if (bInside == IsPlayerInside[Player])
			return;

		IsPlayerInside[Player] = bInside;

		if(bTriggerUsingHandshake)
		{
			UpdateBothInside();
		}
		else if (HasControl())
		{
			UpdateBothInside();
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetBroadcastInsideEvent(bool bInside)
	{
		if (bInside)
			OnBothPlayersInside.Broadcast();
		else
			OnStopBothPlayersInside.Broadcast();
	}
};

// This capability is active while we are waiting for the handshake
class UBothPlayerTriggerIdleCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"CapabilityBlocking");
	default CapabilityTags.Add(n"Movement");
	default CapabilityTags.Add(n"GameplayAction");
	default CapabilityTags.Add(n"ActiveGameplay");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 1;

	AHazePlayerCharacter Player;
	ABothPlayerTrigger Trigger;

    UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams) override
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		Player.TriggerMovementTransition(this);
		
		UObject TempTrigger;
		ConsumeAttribute(n"Trigger", TempTrigger);
		Trigger = Cast<ABothPlayerTrigger>(TempTrigger);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Trigger == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Trigger == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetMutuallyExclusive(n"Movement", true);
		SetMutuallyExclusive(n"GameplayAction", true);
		SetMutuallyExclusive(n"ActiveGameplay", true);
	}

    /* Called when the capability is deactivated, If called when deactivated by DeactivateFromControl it is garanteed to run on the other side */
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(n"Movement", false);
		SetMutuallyExclusive(n"GameplayAction", false);
		SetMutuallyExclusive(n"ActiveGameplay", false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMoveData = MoveComp.MakeFrameMovement(n"BothPlayerTriggerIdle");
			FName AnimationType = n"Movement";

			if(MoveComp.IsAirborne())
			{
				AnimationType = FeatureName::AirMovement;
				FrameMoveData.OverrideStepDownHeight(1.f);	
			}

			if(HasControl() || Player.MovementSyncronizationIsBlocked())
			{
				if(MoveComp.IsGrounded())
				{
					FVector WantedVelocity = MoveComp.GetVelocity().GetClampedToSize(0.f, MoveComp.MoveSpeed);
					FrameMoveData.ApplyVelocity(WantedVelocity);
				}
				else
				{
					FrameMoveData.ApplyDelta(GetHorizontalAirDeltaMovement(DeltaTime, FVector::ZeroVector, MoveComp.HorizontalAirSpeed));
					FrameMoveData.ApplyActorVerticalVelocity();
					FrameMoveData.ApplyGravityAcceleration();
					FrameMoveData.ApplyTargetRotationDelta();
				}

				FVector WantedLocation = FrameMoveData.GetPendingLocation();
				Trigger.BrushComponent.GetClosestPointOnCollision(WantedLocation, WantedLocation);
				FrameMoveData.SetDeltaFromWorldLocation(WantedLocation);
			}
			else
			{
				FHazeActorReplicationFinalized ConsumedParams;
				CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
				FrameMoveData.ApplyConsumedCrumbData(ConsumedParams);
			}

       		MoveCharacter(FrameMoveData, AnimationType);
			CrumbComp.LeaveMovementCrumb();
		}
	}
}




