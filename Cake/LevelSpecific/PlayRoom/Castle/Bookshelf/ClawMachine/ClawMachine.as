import Cake.LevelSpecific.PlayRoom.Castle.Bookshelf.ClawMachine.ClawMachineLocationActor;
import Cake.LevelSpecific.PlayRoom.Castle.Bookshelf.CutieFleeing;
import Cake.LevelSpecific.PlayRoom.Castle.Bookshelf.ClawMachine.ClawMachine_AnimNotify;

event void FOnPlayersCaughtCutie();
event void FOnPlayersMissedCutie();

enum EClawMachineMove
{
	East,
	South,
	West,
	North,
	Grab,
	CutieCaught,
	ReturnToStart,
	ReturnFinished,
};

class AClawMachine: AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UHazeSkeletalMeshComponentBase MeshBody;
	UPROPERTY()
	AClawMachineLocationActor CurrentLocationActor;
	UPROPERTY()
	AClawMachineLocationActor TargetLocationActor;
	UPROPERTY()
	AClawMachineLocationActor ReturnStartLocationActor;
	UPROPERTY()
	AClawMachineLocationActor ClawMachineLocationActorOne;
	UPROPERTY()
	AClawMachineLocationActor ClawMachineLocationActorTwo;
	UPROPERTY()
	AClawMachineLocationActor ClawMachineLocationActorThree;
	UPROPERTY()
	AClawMachineLocationActor ClawMachineLocationActorFour;
	UPROPERTY()
	AClawMachineLocationActor ClawMachineLocationActorFive;
	UPROPERTY()
	AClawMachineLocationActor ClawMachineLocationActorSix;
	UPROPERTY()
	AClawMachineLocationActor ClawMachineLocationActorSeven;
	UPROPERTY()
	AClawMachineLocationActor ClawMachineLocationActorEight;

	UPROPERTY(DefaultComponent)
	UBoxComponent ClawTriggerReverseCutie;
	UPROPERTY(DefaultComponent)
	UBoxComponent ClawTriggerCutieHasPassedBy;

	UPROPERTY(DefaultComponent, Attach = MeshBody)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ClawMoveNorthSouthAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ClawMoveEastWestAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ClawStopMoveAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ClawReturnToStartAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ClawStartGrabbingAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent FinishStartGrabbingAudioEvent;

	FHazeTimeLike MovementTimeLike;
	default MovementTimeLike.Duration = 2.0f;

	FVector TargetLocation;
	FVector StartLocation;
	bool bClawIsMoving = false;
	bool bClawIsReturningToStart = false;

		
	UPROPERTY()
	FOnPlayersCaughtCutie OnPlayersCaughtCutie;
	UPROPERTY()
	FOnPlayersMissedCutie OnPlayersMissedCutie;
	UPROPERTY()
	ACutieFleeing Cutie;
	UPROPERTY()
	AActor TargetRangeCheckCutieCaught;
	float DistanceFromEachOther;
	float DistanceToCatchCutie = 375.f;
	float DistanceToCatchCutiePassed = 125.f;
	bool ClawTriggerOverlapped = false;
	UPROPERTY()
	bool bClawIsGrabbing = false;
	bool bBlockPlayerInput = false;
	UPROPERTY()
	float X = 0;
	UPROPERTY()
	float Y = 0;

	bool bMayNorth;
	bool bMayWest;
	bool bMayEast;
	bool bMaySouth;

	bool bCodyNorth;
	bool bCodyWest;
	bool bCodyEast;
	bool bCodySouth;

	bool bMayJustMovedClaw;
	bool bCodyJustMovedClaw;

	bool bCutieIsCaught = false;
	bool bCuitePassedBy = false;
	bool bClawGrabCanGetCutie = false;

	private TArray<EClawMachineMove> MoveQueue;

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
	{
		MovementTimeLike.BindUpdate(this, n"OnTimeLineUpdate");
		MovementTimeLike.BindFinished(this, n"OnTimeLineFinished");
		ClawTriggerReverseCutie.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		ClawTriggerCutieHasPassedBy.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlapPassedBy");
		ClawTriggerReverseCutie.AttachToComponent(MeshBody, n"GripBase", EAttachmentRule::SnapToTarget);
		ClawTriggerReverseCutie.AddLocalOffset(FVector(30,0, 125));

		FHazeAnimNotifyDelegate ClawMachineCheckCaughtDelegate;
		ClawMachineCheckCaughtDelegate.BindUFunction(this, n"OnCheckIfPlayersCaughtCuite");
		BindAnimNotifyDelegate(UAnimNotify_ClawCheckCaught::StaticClass(), ClawMachineCheckCaughtDelegate);
		UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_VO_Cutie_InsideClawMachine", 1.f);
		PrintToScreenScaled("InsideClawMach", 3.f);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		//PrintToScreen("QuePosOne  " + QuePosOne);
		//PrintToScreen("QuePosTwo  " + QuePosTwo);
		//PrintToScreen("IsClawMoving:   " + bClawIsMoving);
		//PrintToScreen("CurrentLocation:   " + CurrentLocation);
		//PrintToScreen("TargetLocation:   " + TargetLocation);
		//PrintToScreen("TargetLocationActor:   " + TargetLocationActor);
		//PrintToScreen("CurrentLocationActor:   " + CurrentLocationActor);
		//PrintToScreen("X " + X);
		//PrintToScreen("Y " + Y);
		//PrintToScreen("bCuitePassedBy " + bCuitePassedBy);¨

		if (MoveQueue.Num() != 0)
		{
			if (TryPerformMove(MoveQueue[0]))
				MoveQueue.RemoveAt(0);
		}

		CheckForNewMoves();
	}

	void QueueMove(EClawMachineMove Move)
	{
		if (HasControl())
			NetQueueMove(Move);
	}

	UFUNCTION(NetFunction)
	private void NetQueueMove(EClawMachineMove Move)
	{
		MoveQueue.Add(Move);
	}

	bool TryPerformMove(EClawMachineMove Move)
	{
		switch (Move)
		{
			case EClawMachineMove::East:
			case EClawMachineMove::North:
			case EClawMachineMove::South:
			case EClawMachineMove::West:
				if (bClawIsMoving)
					return false;
				StartMoveClaw(Move);
				return true;
			case EClawMachineMove::Grab:
				StartClawAttack();
				return true;
			case EClawMachineMove::CutieCaught:
				if (bClawIsGrabbing && !bClawGrabCanGetCutie)
					return false;
				TriggerCutieWasCaught();
				return true;
			case EClawMachineMove::ReturnToStart:
				bClawIsReturningToStart = true;
				return true;
			case EClawMachineMove::ReturnFinished:
				bClawIsReturningToStart = false;
				return true;
		}

		return false;
	}

	void CheckForNewMoves()
	{
		if (!HasControl())
			return;
		if (bClawIsMoving)
			return;
		if (bBlockPlayerInput)
			return;
		if (bClawIsReturningToStart)
			return;

		if (GFrameNumber % 2 == 0)
		{
			if (bMayEast && CurrentLocationActor.IsEastValid)
				QueueMove(EClawMachineMove::East);
			else if (bMayNorth && CurrentLocationActor.IsNorthValid)
				QueueMove(EClawMachineMove::North);
			else if (bMaySouth && CurrentLocationActor.IsSouthValid)
				QueueMove(EClawMachineMove::South);
			else if (bMayWest && CurrentLocationActor.IsWestValid)
				QueueMove(EClawMachineMove::West);
		}
		else
		{
			if (bCodyEast && CurrentLocationActor.IsEastValid)
				QueueMove(EClawMachineMove::East);
			else if (bCodyNorth && CurrentLocationActor.IsNorthValid)
				QueueMove(EClawMachineMove::North);
			else if (bCodySouth && CurrentLocationActor.IsSouthValid)
				QueueMove(EClawMachineMove::South);
			else if (bCodyWest && CurrentLocationActor.IsWestValid)
				QueueMove(EClawMachineMove::West);
		}
	}

	UFUNCTION()
	void ClawAttack()
	{
		if(bClawIsGrabbing == true)
			return;
		if(bClawIsReturningToStart == true)
			return;
		if(bBlockPlayerInput == true)
			return;

		QueueMove(EClawMachineMove::Grab);
	}

	void StartClawAttack()
	{
		bBlockPlayerInput = true;
		bCuitePassedBy = false;
		bClawGrabCanGetCutie = false;
		System::SetTimer(this, n"ClawStartGrabbing", 0.75f, false);
		System::SetTimer(this, n"ClawFinishedGrabbing", 4.75f, false);	
		System::SetTimer(this, n"StartReturningToStartLocation", 5.5f, false);		
		System::SetTimer(this, n"FinishedReturningToStartLocation", 6.5f, false);	
	}

	UFUNCTION()
	void ClawStartGrabbing()
	{
		bClawIsGrabbing = true;
		ClawTriggerOverlapped = false;
		HazeAkComp.HazePostEvent(ClawStartGrabbingAudioEvent);
	}

	UFUNCTION()
	void ClawFinishedGrabbing()
	{
		bClawIsGrabbing = false;
		bClawGrabCanGetCutie = false;
		HazeAkComp.HazePostEvent(FinishStartGrabbingAudioEvent);
	}

	UFUNCTION()
	void StartReturningToStartLocation()
	{
		if (!bCutieIsCaught && HasControl())
		{
			auto CurLoc = CurrentLocationActor;

			QueueMove(EClawMachineMove::ReturnToStart);
			while (CurLoc.IsEastValid)
			{
				QueueMove(EClawMachineMove::East);
				CurLoc = CurLoc.East;
			}
			while (CurLoc.IsSouthValid)
			{
				QueueMove(EClawMachineMove::South);
				CurLoc = CurLoc.South;
			}
			QueueMove(EClawMachineMove::ReturnFinished);
		}
	}

	UFUNCTION()
	void FinishedReturningToStartLocation()
	{	
		bBlockPlayerInput = false;

		if(this.HasControl())
		{
			X = 0;
			Y = 0;
		}
	}


	//Checked inside animation
	UFUNCTION()
	void OnCheckIfPlayersCaughtCuite(AHazeActor Actor, UHazeSkeletalMeshComponentBase MeshComp, UAnimNotify AnimNotify)
	{
		bClawGrabCanGetCutie = true;

		if (HasControl())
		{
			if (bCutieIsCaught == true)
				return;
		
			Cutie.QueSwapSpline();
			DistanceFromEachOther = (ActorLocation + FVector(0,0, 1000) - Cutie.SmoothVectorLocation.Value).Size();
			//Print("DistanceFromEachOther" + DistanceFromEachOther, 5.f);

			if(!bCuitePassedBy)
			{
				if(DistanceFromEachOther <= DistanceToCatchCutie)
				{
					if(this.HasControl())
					{
						//Print("CutieWasCaught GZ ", 6.f);
						QueueMove(EClawMachineMove::CutieCaught);
					}
				}
				else
				{
					if(this.HasControl())
					{
						OnPlayersMissedCutie.Broadcast();
					}
				}
			}
			else
			{	
				if(DistanceFromEachOther <= DistanceToCatchCutiePassed)
				{
					if(this.HasControl())
					{
						//Print("CutieWasCaught GZ Passed", 6.f);
						QueueMove(EClawMachineMove::CutieCaught);
					}
				}
				else
				{
					if(this.HasControl())
					{
						OnPlayersMissedCutie.Broadcast();
					}
				}
			}
		}
	}

	void TriggerCutieWasCaught()
	{
		bCutieIsCaught = true;
		OnPlayersCaughtCutie.Broadcast();
		UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_VO_Cutie_InsideClawMachine", 0.f);	
		PrintToScreenScaled("CutieIsCaught", 3.f);
	}


	UFUNCTION()
	void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
	UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if(ClawTriggerOverlapped)
			return;
		if(bCuitePassedBy)
			return;
		if(bCutieIsCaught)
			return;
		
		if(OtherActor == Cutie)
		{
			if(Cutie.HasControl())
			{
				NetReverseDirection();
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetReverseDirection()
	{
		if(ClawTriggerOverlapped == false)
		{
			ClawTriggerOverlapped = true;
			Cutie.ReverseDirection();
		}
	}

	UFUNCTION()
	void OnComponentBeginOverlapPassedBy(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
	UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{		
		if(OtherActor == Cutie)
		{
			if(Cutie.HasControl())
			{
				NetOnCutiePassedBy();
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetOnCutiePassedBy()
	{
		bCuitePassedBy = true;
	}

	UFUNCTION()
	void CodyStandingOnButton(bool North, bool South, bool West, bool East)
	{
		if (Game::Cody.HasControl())
			NetCodyStandingOnButton(North, South, West, East);
	}

	UFUNCTION(NetFunction)
	void NetCodyStandingOnButton(bool North, bool South, bool West, bool East)
	{
		bCodyNorth = North;
		bCodyWest = West;
		bCodyEast = East;
		bCodySouth = South;
	}

	UFUNCTION()
	void MayStandingOnButton(bool North, bool South, bool West, bool East)
	{
		if(Game::May.HasControl())
			NetMayStandingOnButton(North, South, West, East);
	}

	UFUNCTION(NetFunction)
	void NetMayStandingOnButton(bool North, bool South, bool West, bool East)
	{
		bMayNorth = North;
		bMayWest = West;
		bMayEast = East;
		bMaySouth = South;
	}

	void StartMoveClaw(EClawMachineMove Move)
	{
		switch (Move)
		{
			case EClawMachineMove::East:
				TargetLocationActor = CurrentLocationActor.East;
				PlayTimeLine(1, 0);
				if (bClawIsReturningToStart)
					HazeAkComp.HazePostEvent(ClawReturnToStartAudioEvent);
				else if (bClawIsMoving)
					HazeAkComp.HazePostEvent(ClawMoveEastWestAudioEvent);
			break;
			case EClawMachineMove::West:
				TargetLocationActor = CurrentLocationActor.West;
				PlayTimeLine(-1, 0);
				if (bClawIsReturningToStart)
					HazeAkComp.HazePostEvent(ClawReturnToStartAudioEvent);
				else if (bClawIsMoving)
					HazeAkComp.HazePostEvent(ClawMoveEastWestAudioEvent);
			break;
			case EClawMachineMove::North:
				TargetLocationActor = CurrentLocationActor.North;
				PlayTimeLine(0, 1);
				if (bClawIsReturningToStart)
					HazeAkComp.HazePostEvent(ClawReturnToStartAudioEvent);
				else if (bClawIsMoving)
					HazeAkComp.HazePostEvent(ClawMoveNorthSouthAudioEvent);
			break;
			case EClawMachineMove::South:
				TargetLocationActor = CurrentLocationActor.South;
				PlayTimeLine(0, -1);
				if (bClawIsReturningToStart)
					HazeAkComp.HazePostEvent(ClawReturnToStartAudioEvent);
				else if (bClawIsMoving)
					HazeAkComp.HazePostEvent(ClawMoveNorthSouthAudioEvent);
			break;
		}
	}

	UFUNCTION()
	void PlayTimeLine(float XLocal, float YLocal)
	{	
		if(TargetLocationActor != nullptr)
		{
			X = XLocal;
			Y = YLocal;
			MovementTimeLike.SetPlayRate(1.6);
			TargetLocation = TargetLocationActor.GetActorLocation();
			StartLocation = GetActorLocation();
			bClawIsMoving = true;
			MovementTimeLike.PlayFromStart();
		}
	}


	UFUNCTION()
	void OnTimeLineUpdate(float Duration)
	{
		FVector NewLocation;
		NewLocation = FMath::Lerp(StartLocation, TargetLocation, Duration);
		SetActorLocation(NewLocation);
	}
	
	UFUNCTION()
	void OnTimeLineFinished()
	{
		X = 0;
		Y = 0;

		if(TargetLocationActor != nullptr)
			CurrentLocationActor = TargetLocationActor;

		bClawIsMoving = false;
		TargetLocationActor = nullptr;
		HazeAkComp.HazePostEvent(ClawStopMoveAudioEvent);
		
	}
}
