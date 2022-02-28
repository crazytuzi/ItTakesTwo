import Peanuts.Spline.SplineComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

UCLASS(Abstract)
class ASpaceWeightTrackPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent UpArrow;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent DownArrow;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.bRenderWhileDisabled = true;
	default DisableComponent.AutoDisableRange = 8000.f;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;

	UPROPERTY()
	AHazeActor StartSpline;

	UPROPERTY()
	AHazeActor TopSpline;

	UPROPERTY()
	AHazeActor MiddleSpline;

	UPROPERTY()
	AHazeActor BottomSpline;

	UPROPERTY()
	AHazeActor EndSpline;

	UHazeSplineComponent StartSplineComp;
	UHazeSplineComponent TopSplineComp;
	UHazeSplineComponent MiddleSplineComp;
	UHazeSplineComponent BottomSplineComp;
	UHazeSplineComponent EndSplineComp;

	UHazeSplineComponent CurrentSplineComp;

	TArray<UHazeSplineComponent> SplineComps;

	float DistanceAlongCurrentSpline;
	float MovementSpeed = 750.f;

	bool bMovingForward = true;

	UPROPERTY(NotEditable)
	bool bMayOnPlatform = false;
	UPROPERTY(NotEditable)
	bool bCodyOnPlatform = false;

	bool bMoving = true;

	float StopTime = 2.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartSplineComp = UHazeSplineComponent::Get(StartSpline);
		TopSplineComp = UHazeSplineComponent::Get(TopSpline);
		MiddleSplineComp = UHazeSplineComponent::Get(MiddleSpline);
		BottomSplineComp = UHazeSplineComponent::Get(BottomSpline);
		EndSplineComp = UHazeSplineComponent::Get(EndSpline);

		CurrentSplineComp = StartSplineComp;

		SplineComps.Add(StartSplineComp);
		SplineComps.Add(TopSplineComp);
		SplineComps.Add(MiddleSplineComp);
		SplineComps.Add(BottomSplineComp);
		SplineComps.Add(EndSplineComp);

		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"LandOnPlatform");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"LeavePlatform");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);
	}

	UFUNCTION(NotBlueprintCallable)
	void LandOnPlatform(AHazePlayerCharacter Player, FHitResult Hit)
	{
		if (Player == Game::GetMay())
			bMayOnPlatform = true;
		else
			bCodyOnPlatform = true;

		BP_LandOnPlatform(Player.IsCody());
	}

	UFUNCTION(NotBlueprintCallable)
	void LeavePlatform(AHazePlayerCharacter Player)
	{
		if (Player == Game::GetMay())
			bMayOnPlatform = false;
		else
			bCodyOnPlatform = false;

		BP_LeavePlatform(Player.IsCody());
	}

	UFUNCTION(BlueprintEvent)
	void BP_LandOnPlatform(bool bTop) {}

	UFUNCTION(BlueprintEvent)
	void BP_LeavePlatform(bool bTop) {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (HasControl())
		{
			if (!bMoving)
				return;

			if (bMovingForward)
			{
				DistanceAlongCurrentSpline += MovementSpeed * DeltaTime;
				if (DistanceAlongCurrentSpline >= CurrentSplineComp.SplineLength)
				{
					SelectNextSpline();
				}
			}
			else
			{
				DistanceAlongCurrentSpline -= MovementSpeed * DeltaTime;
				if (DistanceAlongCurrentSpline <= 0.f )
				{
					SelectPreviousSpline();
				}
			}

			FVector Loc = CurrentSplineComp.GetLocationAtDistanceAlongSpline(DistanceAlongCurrentSpline, ESplineCoordinateSpace::World);

			SetActorLocation(Loc);
			CrumbComponent.LeaveMovementCrumb();
		}
		else 
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);

			SetActorLocation(ConsumedParams.Location);
		}
	}

	UFUNCTION()
	void Crumb_StartMoving(const FHazeDelegateCrumbData& CrumbData)
	{
		BP_StartMoving(CrumbData.GetActionState(n"Forward"));
	}

	UFUNCTION()
	void Crumb_StopMoving(const FHazeDelegateCrumbData& CrumbData)
	{
		BP_StopMoving(CrumbData.GetActionState(n"AtStart"));
	}

	void SelectNextSpline()
	{
		if (!HasControl())
			return;

		if (CurrentSplineComp == EndSplineComp)
		{
			DistanceAlongCurrentSpline = EndSplineComp.SplineLength;
			bMovingForward = false;
			bMoving = false;
			System::SetTimer(this, n"StartMoving", StopTime, false);
			FHazeDelegateCrumbParams CrumbParams;
			CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_StopMoving"), CrumbParams);
			return;
		}

		else if (CurrentSplineComp == StartSplineComp)
		{
			if (bMayOnPlatform && bCodyOnPlatform)
			{
				CurrentSplineComp = MiddleSplineComp;
			}
			else if (bMayOnPlatform)
			{
				CurrentSplineComp = TopSplineComp;
			}
			else if (bCodyOnPlatform)
			{
				CurrentSplineComp = BottomSplineComp;
			}
			else
			{
				CurrentSplineComp = MiddleSplineComp;
			}
		}
		else
		{
			CurrentSplineComp = EndSplineComp;
		}

		DistanceAlongCurrentSpline = 0.f;
	}

	void SelectPreviousSpline()
	{
		if (!HasControl())
			return;

		if (CurrentSplineComp == StartSplineComp)
		{
			DistanceAlongCurrentSpline = 0.f;
			bMovingForward = true;
			bMoving = false;
			System::SetTimer(this, n"StartMoving", StopTime, false);
			FHazeDelegateCrumbParams CrumbParams;
			CrumbParams.AddActionState(n"AtStart");
			CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_StopMoving"), CrumbParams);
			return;
		}

		else if (CurrentSplineComp == EndSplineComp)
		{
			if (bMayOnPlatform && bCodyOnPlatform)
			{
				CurrentSplineComp = MiddleSplineComp;
			}
			else if (bMayOnPlatform)
			{
				CurrentSplineComp = TopSplineComp;
			}
			else if (bCodyOnPlatform)
			{
				CurrentSplineComp = BottomSplineComp;
			}
			else
			{
				CurrentSplineComp = MiddleSplineComp;
			}
		}
		else
		{
			CurrentSplineComp = StartSplineComp;
		}

		DistanceAlongCurrentSpline = CurrentSplineComp.SplineLength;
	}

	UFUNCTION(NotBlueprintCallable)
	void StartMoving()
	{
		bMoving = true;
		
		FHazeDelegateCrumbParams CrumbParams;
		
		if (bMovingForward)
		{
			CrumbParams.AddActionState(n"Forward");
		}

		CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_StartMoving"), CrumbParams);
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartMoving(bool bForward) 
	{ }

	UFUNCTION(BlueprintEvent)
	void BP_StopMoving(bool bAtStart) 
	{ }
}