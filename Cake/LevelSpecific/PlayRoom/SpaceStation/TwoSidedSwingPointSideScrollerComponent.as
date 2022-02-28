import Cake.LevelSpecific.PlayRoom.SpaceStation.TwoSidedSwingPoint;
import Vino.Movement.PlaneLock.PlaneLockActor;
import Cake.LevelSpecific.PlayRoom.SpaceStation.TwoSidedSwingPointSideScrollerCapability;
import Cake.LevelSpecific.PlayRoom.VOBanks.SpacestationVOBank;
import Peanuts.Network.TransitionHelpers;

class UTwoSidedSwingPointSideScrollerComponent : USceneComponent
{
	ATwoSidedSwingPoint ParentSwingPoint;

	UPROPERTY()
	ETwoSidedSwingPointSideScrollerRotationType RotationType;

	UPROPERTY()
	APlaneLockActor MayPlaneLockActor;

	UPROPERTY()
	APlaneLockActor CodyPlaneLockActor;

	UPROPERTY()
	FHazeTimeLike MovementTimeLike;

	UPROPERTY()
	USpacestationVOBank VOBank;

	bool bMayAttached = false;
	bool bCodyAttached = false;
	bool bBothPlayersAttached = false;

	bool bMayLocked = false;
	bool bCodyLocked = false;

	bool bMoving = false;

	FVector StartLocation;
	UPROPERTY(meta = (MakeEditWidget))
	FVector EndLocation;

	FRotator StartRotation;

	float StopTime = 4.f;
	FTimerHandle StopTimerHandle;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ParentSwingPoint = Cast<ATwoSidedSwingPoint>(Owner);
		if (ParentSwingPoint == nullptr)
			return;

		ParentSwingPoint.TopSwingComp.OnSwingPointAttached.AddUFunction(this, n"AttachedToTop");
		ParentSwingPoint.BottomSwingComp.OnSwingPointAttached.AddUFunction(this, n"AttachedToBottom");

		ParentSwingPoint.TopSwingComp.OnSwingPointDetached.AddUFunction(this, n"DetachedFromTop");
		ParentSwingPoint.BottomSwingComp.OnSwingPointDetached.AddUFunction(this, n"DetachedFromBottom");

		MovementTimeLike.BindUpdate(this, n"UpdateMove");
		MovementTimeLike.BindFinished(this, n"FinishMove");

		StartLocation = Owner.ActorLocation;
		EndLocation = Owner.ActorTransform.TransformPosition(EndLocation);

		StartRotation = Owner.ActorRotation;

		ParentSwingPoint.OnSwingPointHidden.AddUFunction(this, n"SwingPointHidden");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.SetAnimBoolParam(n"CrazySpacestationSwingpoint", false);
			Player.SetCapabilityActionState(n"TwoSidedSwingPointSideScroller", EHazeActionState::Inactive);
		}
	}

	UFUNCTION()
	void AttachedToTop(AHazePlayerCharacter Player)
	{
		Player.SetAnimBoolParam(n"CrazySpacestationSwingpoint", true);

		if (Player.HasControl())
		{
			if (bMayLocked)
				return;

			bMayAttached = true;
			bMayLocked = true;
			Player.SetCapabilityActionState(n"TwoSidedSwingPointSideScroller", EHazeActionState::Active);
			NetCheckIfOtherPlayerIsLocked(Player);
		}
	}

	UFUNCTION()
	void AttachedToBottom(AHazePlayerCharacter Player)
	{
		Player.SetAnimBoolParam(n"CrazySpacestationSwingpoint", true);

		if (Player.HasControl())
		{
			if (bCodyLocked)
				return;

			bCodyAttached = true;
			bCodyLocked = true;
			Player.SetCapabilityActionState(n"TwoSidedSwingPointSideScroller", EHazeActionState::Active);
			NetCheckIfOtherPlayerIsLocked(Player);
		}
	}

	UFUNCTION(NetFunction)
	void NetCheckIfOtherPlayerIsLocked(AHazePlayerCharacter Player)
	{
		if (Player.IsCody())
		{
			if (Game::GetMay().HasControl())
			{
				if (bMayAttached)
				{
					NetStartMoving();
				}
				else
				{
					NetUnlockPlayer(Player);
				}
			}
		}
		else
		{
			if (Game::GetCody().HasControl())
			{
				if (bCodyAttached)
				{
					NetStartMoving();
				}
				else
				{
					NetUnlockPlayer(Player);
				}
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetUnlockPlayer(AHazePlayerCharacter Player)
	{
		if (!Player.HasControl())
			return;

		if (Player.IsMay())
		{
			if (bMayLocked)
			{
				bMayLocked = false;
				Player.SetCapabilityActionState(n"TwoSidedSwingPointSideScroller", EHazeActionState::Inactive);
			}
		}
		else
		{
			if (bCodyLocked)
			{
				bCodyLocked = false;
				Player.SetCapabilityActionState(n"TwoSidedSwingPointSideScroller", EHazeActionState::Inactive);
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetStartMoving()
	{
		if (bMoving)
			return;

		bMoving = true;
		bBothPlayersAttached = true;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.BlockCapabilities(n"SwingingDetach", this);
			Player.SetCapabilityActionState(n"TwoSidedSwingPointSideScroller", EHazeActionState::Inactive);
		}

		MovementTimeLike.PlayFromStart();

		ParentSwingPoint.bPermanentlyExposed = true;

		if (MayPlaneLockActor != nullptr && CodyPlaneLockActor != nullptr)
		{
			MayPlaneLockActor.AttachToActor(Owner, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
			CodyPlaneLockActor.AttachToActor(Owner, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		}

		VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationSwingEffortCody");
		VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationSwingEffortMay");
	}

	UFUNCTION()
	void SwingPointHidden()
	{
		if (ParentSwingPoint.bTopIsMainSwingPoint)
			DetachedFromBottom(Game::GetCody());
		else
			DetachedFromTop(Game::GetMay());
	}

	UFUNCTION()
	void DetachedFromTop(AHazePlayerCharacter Player)
	{
		Player.SetAnimBoolParam(n"CrazySpacestationSwingpoint", false);
		bBothPlayersAttached = false;
		bMayAttached = false;
	}

	UFUNCTION()
	void DetachedFromBottom(AHazePlayerCharacter Player)
	{
		Player.SetAnimBoolParam(n"CrazySpacestationSwingpoint", false);
		bBothPlayersAttached = false;
		bCodyAttached = false;
	}

	UFUNCTION()
	void UpdateMove(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(StartLocation, EndLocation, CurValue);
		Owner.SetActorLocation(CurLoc);
		
		FRotator CurRot = StartRotation;

		if (RotationType == ETwoSidedSwingPointSideScrollerRotationType::Roll)
		{
			float CurRoll = FMath::Lerp(0.f, 1080.f, CurValue);
			CurRot.Roll = CurRoll;
		}
		else if (RotationType == ETwoSidedSwingPointSideScrollerRotationType::Yaw)
		{
			float CurYaw = FMath::Lerp(StartRotation.Yaw, StartRotation.Yaw + 1080.f, CurValue);
			CurRot.Yaw = CurYaw;

			MayPlaneLockActor.SetActorRotation(FRotator(0.f, CurYaw + 90.f, 0.f));
			CodyPlaneLockActor.SetActorRotation(FRotator(0.f, CurYaw + 90.f, 0.f));
		}
		else if (RotationType == ETwoSidedSwingPointSideScrollerRotationType::RollYaw)
		{
			float CurRoll = FMath::Lerp(0.f, 720.f, CurValue);
			float CurYaw = FMath::Lerp(StartRotation.Yaw, StartRotation.Yaw + 720.f, CurValue);

			CurRot.Roll = CurRoll;
			CurRot.Yaw = CurYaw;
		}

		Owner.SetActorRotation(CurRot);

		FVector CurWorldUp = ParentSwingPoint.BodyRoot.UpVector;

		Game::GetCody().ChangeActorWorldUp(CurWorldUp);
		Game::GetMay().ChangeActorWorldUp(-CurWorldUp);
	}

	UFUNCTION()
	void FinishMove()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.UnblockCapabilities(n"SwingingDetach", this);
			Player.SetCapabilityActionState(n"TwoSidedSwingPointSideScroller", EHazeActionState::Inactive);
		}
	}
}

enum ETwoSidedSwingPointSideScrollerRotationType
{
	Roll,
	Yaw,
	RollYaw,
}