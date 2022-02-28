import Cake.LevelSpecific.PlayRoom.Circus.SlingShot.SlingShot;
import Cake.LevelSpecific.PlayRoom.Circus.SlingShot.SlingShotWidget;


class USlingShotMovementCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ASlingShotActor Slingshot;
	FHazeAcceleratedFloat Velocity;
	float Speed = 25;
	float RetractSpeed = 55;
	FVector Movedir = FVector::ZeroVector;
	UHazeSmoothSyncFloatComponent SyncedSpeed;
	UHazeSmoothSyncFloatComponent SyncedDistance;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Slingshot = Cast<ASlingShotActor>(Owner);
		SyncedSpeed = UHazeSmoothSyncFloatComponent::GetOrCreate(Slingshot, n"SlingShotSyncedSped");
		SyncedDistance = UHazeSmoothSyncFloatComponent::GetOrCreate(Slingshot, n"SlingShotSyncedDistance");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Slingshot.bReset)
			return EHazeNetworkActivation::DontActivate;
		else
			return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Slingshot.bReset)
			return EHazeNetworkDeactivation::DeactivateLocal;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			// First we need to decide farhtest pont that handle can be pulled
			FVector FurthestPullPoint;

			if (Slingshot.PullAmount > 1.1)
			{
				FurthestPullPoint = Slingshot.MaxPulledBackByTwoPlayersPosition.WorldLocation;
			}
			
			else
			{
				FurthestPullPoint = Slingshot.NoPlayerPullsPosition.WorldLocation;
			}
			
			// Then we need to check wether handle is past that point, if so set desired speed to negative if we are far past that point or 0 if we are at that ACymbalSwingPoint
			FVector HandleForwardDir = Slingshot.HandleParent.ForwardVector;
			FVector DirToFurthestPillPoint = FurthestPullPoint - Slingshot.HandleParent.WorldLocation;
			float HandleToFurthestPointDot = DirToFurthestPillPoint.GetSafeNormal().DotProduct(HandleForwardDir);

			float DistanceFromHandle = Slingshot.HandleParent.WorldLocation.Distance(FurthestPullPoint);
			float MoveSpeed = 0;

			// Handle rebounds to Furhtest Position
			if (HandleToFurthestPointDot < 0 && DistanceFromHandle > 50)
			{
				MoveSpeed = -RetractSpeed;
			}

			else if (HandleToFurthestPointDot > 0 && DistanceFromHandle > 50)
			{
				MoveSpeed = RetractSpeed;
			}
			
			// Sync audio
			SyncedDistance.Value = Slingshot.HandleParent.WorldLocation.Distance(Slingshot.MaxPulledBackByTwoPlayersPosition.WorldLocation);
			SyncedSpeed.Value = MoveSpeed;
			
			// Create a vector and determine the direction of the move
			Movedir = Slingshot.HandleParent.ForwardVector * Velocity.Value;
			Velocity.AccelerateTo(MoveSpeed * 0.1f, 0.5f, DeltaTime);
			
			// Perform move of the actor to right location
			Slingshot.HandleParent.SetWorldLocation(Slingshot.HandleParent.WorldLocation + Movedir);
			Slingshot.PullBackPositionSync.Value = Slingshot.HandleParent.GetWorldLocation();
			UpdateMoveState();	
		}

		else
		{
			Movedir = Slingshot.PullBackPositionSync.Value - Slingshot.HandleParent.WorldLocation;
			Slingshot.HandleParent.WorldLocation = Slingshot.PullBackPositionSync.Value;
		}

		float NormalizedHandleDistanceToMax = SyncedDistance.Value;
		NormalizedHandleDistanceToMax /= 704;

		Slingshot.HazeAkComp.SetRTPCValue("Rtpc_Gadget_SlingShot_PullDistance", NormalizedHandleDistanceToMax);
		Slingshot.HazeAkComp.SetRTPCValue("Rtpc_Gadget_SlingShot_PullAmount", SyncedSpeed.Value);

		// Print("PullDist" + NormalizedHandleDistanceToMax, 0.f);
		// Print("PullAmount" + SyncedSpeed.Value, 0.f);
	}

	void UpdateMoveState()
	{
		if (Movedir.Size() < 0.5f && Slingshot.MoveState != ESlingShotMoveState::NotMoving)
		{
			NetSyncMoveState(ESlingShotMoveState::NotMoving);
		}

		else if (Movedir.GetSafeNormal().DotProduct(Slingshot.HandleParent.ForwardVector) > 0 && Slingshot.MoveState != ESlingShotMoveState::SlideForward)
		{
			NetSyncMoveState(ESlingShotMoveState::SlideForward);
		}

		else if (Slingshot.MoveState != ESlingShotMoveState::Pullback && Movedir.GetSafeNormal().DotProduct(Slingshot.HandleParent.ForwardVector) < 0)
		{
			NetSyncMoveState(ESlingShotMoveState::Pullback);
		}
	}

	UFUNCTION(NetFunction)
	void NetSyncMoveState(ESlingShotMoveState MoveState)
	{
		Slingshot.MoveState = MoveState;
	}
}