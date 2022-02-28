import Cake.LevelSpecific.SnowGlobe.Snowfolk.ConnectedHeightSplineFollowerComponent;
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightResponseComponent;
import Cake.LevelSpecific.SnowGlobe.Snowfolk.SnowFolkMovementComponent;
import Cake.LevelSpecific.SnowGlobe.SnowFolk.SnowFolkProximityComponent;
import Cake.LevelSpecific.SnowGlobe.SnowFolk.SnowFolkFauxCollisionComponent;
import Cake.LevelSpecific.SnowGlobe.SnowFolk.SnowFolkGreetComponent;
import Cake.LevelSpecific.SnowGlobe.Snowfolk.SnowFolkNames;
import Cake.Environment.BreakableComponent;
import Vino.Interactions.InteractionComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackComponent;
import Vino.BouncePad.BouncePadResponseComponent;
import Vino.Movement.MovementSystemTags;
import Peanuts.Aiming.AutoAimTarget;
import Peanuts.Audio.VO.PatrolActorAudioComponent;
import Rice.Math.MathStatics;
import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

event void FOnSnowfolkEnabled();
event void FSnowFolkDisabled();

enum ESnowFolkDetailLevel
{
	Visible,
	Lodded,
	Hidden
}

class USnowfolkSplineFollowerVisualizerComponent : UActorComponent { }
class USnowfolkSplineFollowerVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USnowfolkSplineFollowerVisualizerComponent::StaticClass();

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		ASnowfolkSplineFollower Folk = Cast<ASnowfolkSplineFollower>(Component.Owner);

		if (Folk == nullptr)
			return;

		// DrawCircle(Folk.Collision.ShapeCenter, Folk.ProximityComp.ProximityRadius, FLinearColor::DPink, 3.f, FVector::UpVector, 32);
		// if (!Folk.GreetComp.bDisableGreeting)
		// 	DrawArc(Folk.Collision.ShapeCenter, Folk.GreetComp.GreetAngle, Folk.ProximityComp.ProximityRadius, Folk.ActorForwardVector, FLinearColor::Yellow, 3.f, FVector::UpVector);

		UConnectedHeightSplineFollowerComponent FollowerComp = Folk.SplineFollowerComponent;
		UConnectedHeightSplineComponent Spline = FollowerComp.Spline;

		if (Spline != nullptr)
		{
			FVector InitialLocation = Spline.GetLocationAtDistanceAlongSpline(FollowerComp.DistanceOnSpline, ESplineCoordinateSpace::World);
			DrawDashedLine(Folk.ActorLocation, InitialLocation, DashSize = 20.f);
			DrawPoint(InitialLocation, Size = 20.f);

			float PointDistance = 500.f;
			FVector PointOffset = FVector::UpVector * 10.f;
			int NumPoints = FMath::CeilToInt(Spline.SplineLength / PointDistance);
			for (int i = 0; i < NumPoints; ++i)
			{
				float CurrentDistance = FMath::Clamp(i * PointDistance,
					0.f, Spline.SplineLength);

				FVector Point = Spline.GetTransformAtDistanceAndOffset(CurrentDistance,
					Folk.MovementComp.GetOffsetFromSine(CurrentDistance)).Location;

				float NextDistance = FMath::Clamp((i + 1) * PointDistance,
					0.f, Spline.SplineLength);

				FVector NextPoint = Spline.GetTransformAtDistanceAndOffset(NextDistance,
					Folk.MovementComp.GetOffsetFromSine(NextDistance)).Location;

				DrawLine(Point + PointOffset, NextPoint + PointOffset, FLinearColor::Green, 20.f, true);
			}
		}
	}
}

class ASnowfolkSplineFollower : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent)
	USnowfolkSplineFollowerVisualizerComponent VisualizerComponent;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Collision)
	UHazeSkeletalMeshComponentBase SkeletalMeshComponent;
	default SkeletalMeshComponent.bUseAttachParentBound = true;

	UPROPERTY(Category = "VOBank")
	UFoghornVOBankDataAssetBase VOLevelBank;

	// Used for the faux collision capability, must have query enabled
	UPROPERTY(DefaultComponent)
	UCapsuleComponent Collision;
	default Collision.CapsuleHalfHeight = 150.f;
	default Collision.CapsuleRadius = 120.f;
	default Collision.bGenerateOverlapEvents = false;
	default Collision.CollisionProfileName = n"Custom";
	default Collision.CollisionResponseToAllChannels = ECollisionResponse::ECR_Ignore;
	default Collision.CollisionEnabled = ECollisionEnabled::QueryOnly;

	UPROPERTY(DefaultComponent, Attach = Collision)
	UNiagaraComponent NiagaraComponent;
	default NiagaraComponent.bUseAttachParentBound = true;

	UPROPERTY(DefaultComponent)
	UConnectedHeightSplineFollowerComponent SplineFollowerComponent;

	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent ImpactComponent;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;
	default CrumbComponent.bTickWhileDisabled = true;
	default CrumbComponent.SyncIntervalType = EHazeCrumbSyncIntervalType::VerySlow;
	default CrumbComponent.UpdateSettings.OptimalCount = 2;

	UPROPERTY(DefaultComponent)
	UBouncePadResponseComponent BounceResponseComponent;

	UPROPERTY(DefaultComponent)
	USnowballFightResponseComponent SnowballResponseComponent;

	UPROPERTY(DefaultComponent)
	USnowFolkMovementComponent MovementComp;
	
	UPROPERTY(DefaultComponent)
	USnowFolkProximityComponent ProximityComp;

	UPROPERTY(DefaultComponent)
	USnowFolkFauxCollisionComponent FauxCollisionComp;

	UPROPERTY(DefaultComponent)
	USnowFolkGreetComponent GreetComp;

	UPROPERTY(DefaultComponent)
	UPatrolActorAudioComponent PatrolAudioComp;
	default PatrolAudioComp.bAutoRegister = false;

	UPROPERTY(DefaultComponent, Attach = Collision)
	UHazeAkComponent SnowfolkHazeAkComp;
	default SnowfolkHazeAkComp.bUseAttachParentBound = true;

	UPROPERTY(DefaultComponent, Attach = Collision)
	UAutoAimTargetComponent AutoAimTargetComponent;
	default AutoAimTargetComponent.RelativeLocation = FVector::UpVector * 5.f;
	default AutoAimTargetComponent.AutoAimMaxAngle = 15.f;
	default AutoAimTargetComponent.bUseAttachParentBound = true;

	UPROPERTY(Category = "Snowfolk")
	UHazeCapabilitySheet SnowfolkPlayerInteractionCapabilitySheet;

	UPROPERTY(Category = "Snowfolk")
	UHazeCapabilitySheet SnowFolkCapabilitySheet;
	
	UPROPERTY(Category = "Snowfolk")
	UHazeCapabilitySheet SnowfolkSnowballCapabilitySheet;

	UPROPERTY(Category = "Snowfolk")
	USkeletalMesh CharacterMesh;

	UPROPERTY(Category = "Events")
	FSnowFolkDisabled OnSnowFolkDisabled;

	UPROPERTY(Category = "Snowfolk|Settings")
	bool bIsReady = false;

	UPROPERTY(Category = "Snowfolk|Settings")
	bool bCanMove;

	UPROPERTY(Category = "Snowfolk|Settings")
	bool bCanBeKnocked = true;
	
	UPROPERTY(Category = "Snowfolk|Settings")
	bool bStartDisabled;

	UPROPERTY(Category = "Snowfolk|Settings")
	bool bSnowballThrower = true;

	UPROPERTY(Category = "Snowfolk|Settings")
	bool bUseAvoidance = true;

	// X = AlongSpline, Y = SideOffset
	UPROPERTY(Category = "Snowfolk|Settings")
	FVector2D AvoidanceArea = FVector2D(1000.f, 400.f);

	UPROPERTY(Category = "Snowfolk|Settings")
	float AvoidanceWeight = 1.f;

	UPROPERTY(Category = "Snowfolk|Settings")
	bool bIsHatDisabled;

	UPROPERTY(Category = "Snowfolk|Settings")
	ESnowFolkActivationLevel ActivationLevel;

	// Unused at the moment
	// UPROPERTY(Category = "Snowfolk|Movement")
	// float WaitTime = 5.f;
	// float WaitTimer = 0.f;

	// UPROPERTY(Category = "Snowfolk|Movement")
	// float WaitAtEveryDistance = 0.f;
	// float WaitAtDistance = WaitAtEveryDistance;

	UPROPERTY(Category = "Snowfolk|Impact")
	float ImpactVelocityThreshold = 1200.f;

	UPROPERTY(Category = "Snowfolk|Impact")
	float ImpactDuration = 0.8f;
	
	UPROPERTY(Category = "Snowfolk|Impact")
	UForceFeedbackEffect ImpactForceFeedback;

	UPROPERTY(Category = "Snowfolk|Fall")
	float FallDuration = 1.f;

	UPROPERTY(Category = "Snowfolk|Fall")
	float RecoveryDuration = 2.5f;

	UPROPERTY(Category = "Snowfolk|Bounce")
	float BounceVerticalVelocity = 1300.f;

	UPROPERTY(Category = "Snowfolk|Bounce")
	float BounceHorizontalVelocityModifier = 0.5f;

	UPROPERTY(Category = "Snowfolk|Bounce")
	float SquishDuration = 0.3f;

	UPROPERTY(EditDefaultsOnly, Category = "Snowfolk|Bounce")
	TSubclassOf<UHazeCapability> BouncePadCapabilityClass;

	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Snowfolk|Animation")
	float BSSpeed = 0.f;

	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Snowfolk|Animation")
	float BSLeanValue = 0.f;

	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Snowfolk|Animation")
	FVector LookAtLocation;

	// Unused, but is retrieved in ABP
	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Snowfolk|State")
	bool bIsWaiting;

	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Snowfolk|State")
	bool bIsMoving;

	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Snowfolk|State")
	bool bIsJumpedOn;

	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Snowfolk|State")
	bool bIsRecovering;

	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Snowfolk|State")
	bool bIsHit;

	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Snowfolk|State")
	bool bHitFromLeft;

	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Snowfolk|State")
	bool bIsDown;

	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Snowfolk|State")
	bool bEnableLookAt;

	UPROPERTY(Category = "Snowfolk|VFX")
	UNiagaraSystem VFX_SkateEffect;

	UPROPERTY(Category = "Snowfolk|VFX")
	UNiagaraSystem VFX_WalkEffect;

	UPROPERTY(Category = "Snowfolk|Audio")
	UAkAudioEvent ProjectileHitAudioEvent;
	
	UPROPERTY(Category = "Snowfolk|Audio")
	UAkAudioEvent BounceAudioEvent;

	UPROPERTY(Category = "Snowfolk|Events")
	FOnSnowfolkEnabled OnSnowfolkEnabled;

	UPROPERTY(Category = "Snowfolk|Debug")
	bool bDrawDebug;

//	float ClosestPlayerDistanceSquared = 0.f;
//	float SimplifyFootprintDistance = 10000.f;

	bool bIsSnowfolkActivated = true;
	bool bIsSnowfolkVisible = true;
	TSet<FName> DisableTags;

	bool bMovementIsBlocked = false;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UPROPERTY(Category = "Snowfolk|Optimization")
	const float LodDistance = 9000.f;

	ESnowFolkDetailLevel DetailLevel = ESnowFolkDetailLevel::Visible;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MovementComp.SplineFollowerComp = SplineFollowerComponent;

		SkeletalMeshComponent.SetSkeletalMesh(CharacterMesh);
		SplineFollowerComponent.SetSplineActorSpline();

		SkeletalMeshComponent.SetCullDistance(Editor::GetDefaultCullingDistance(SkeletalMeshComponent) * CullDistanceMultiplier);

		if (SplineFollowerComponent.Spline != nullptr)
			SplineFollowerComponent.SetDistanceAndOffsetAtWorldLocation(ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Capability::AddPlayerCapabilitySheetRequest(SnowfolkPlayerInteractionCapabilitySheet);
		Capability::AddPlayerCapabilityRequest(BouncePadCapabilityClass);
		AddCapabilitySheet(SnowFolkCapabilitySheet);

		if (!MovementComp.bIsSkating && bSnowballThrower)
			AddCapabilitySheet(SnowfolkSnowballCapabilitySheet);

		if (MovementComp.bAlwaysUpright)
			SplineFollowerComponent.FootPrintSamples = 1;

		// VFX
		NiagaraComponent.SetAsset(VFX_SkateEffect);
		NiagaraComponent.SetNiagaraVariableFloat("SpawnRate", 0.f);
		NiagaraComponent.Activate();

		// Initial Setup
		if (SplineFollowerComponent.Spline != nullptr)
			bIsMoving = true;
		else
			bCanMove = false;

		if (bStartDisabled)
			DeactivateSnowfolk();
		else if(PatrolAudioComp.bAutoRegister)		
			PatrolAudioComp.BP_RegisterToManager();

		if (bIsHatDisabled)
			SkeletalMeshComponent.HideBoneByName(n"Hat", EPhysBodyOp::PBO_None);

		if (bCanMove)
			GreetComp.bDisableGreeting = true;

		SplineFollowerComponent.Transform = ActorTransform;
		CrumbComponent.IncludeCustomParamsInActorReplication(ActorTransform.Location, ActorTransform.Rotator(), this);
	}
	
	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		// Capability::RemovePlayerCapabilitySheetRequest(SnowfolkPlayerInteractionCapabilitySheet);
		Capability::RemovePlayerCapabilityRequest(BouncePadCapabilityClass);
	}

	void SetSnowfolkDetailLevel(ESnowFolkDetailLevel NewLevel)
	{
		/*
		Debug drawing aheheh
		switch(NewLevel)
		{
			case ESnowFolkDetailLevel::Visible:
				System::DrawDebugSphere(MovementComp.CurrentTransform.Location, 800.f, LineColor = FLinearColor::Green, Thickness = 5.f);
				break;

			case ESnowFolkDetailLevel::Lodded:
				System::DrawDebugSphere(MovementComp.CurrentTransform.Location, 800.f, LineColor = FLinearColor::Yellow, Thickness = 5.f);
				break;

			case ESnowFolkDetailLevel::Hidden:
				System::DrawDebugSphere(MovementComp.CurrentTransform.Location, 800.f, LineColor = FLinearColor::Red, Thickness = 5.f);
				break;
		}
		*/

		if (NewLevel == DetailLevel)
			return;

		DetailLevel = NewLevel;

		if (HasControl())
		{
			// We became lodded, so disable the actor
			// FUGLY CODE ALERT WEE WOO WEE WOO
			// We have to disable on control _before_ leaving the delegate crumb to disable on remote
			// Otherwise DeactivationCrumbs will get stuck in the crumb-trail, because they come in after the delegate crumb
			if (bIsSnowfolkVisible && DetailLevel != ESnowFolkDetailLevel::Visible)
			{
				HideSnowfolk();
				CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbedRemoteHideSnowfolk"), FHazeDelegateCrumbParams());
			}

			if (!bIsSnowfolkVisible && DetailLevel == ESnowFolkDetailLevel::Visible)
			{
				ShowSnowfolk();
				CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbedRemoteShowSnowfolk"), FHazeDelegateCrumbParams());
			}
		}
	}

	UFUNCTION()
	void CrumbedRemoteHideSnowfolk(FHazeDelegateCrumbData Params)
	{
		// Control disabled locally, so only remotes allowed past this point!
		if (HasControl())
			return;

		HideSnowfolk();
	}

	UFUNCTION()
	void CrumbedRemoteShowSnowfolk(FHazeDelegateCrumbData Params)
	{
		// Control enabled locally, so only remotes allowed past this point!
		if (HasControl())
			return;

		ShowSnowfolk();
	}
	
	UFUNCTION()
	void ResetSnowfolk()
	{
		SplineFollowerComponent.SetSplineActorSpline();
		SplineFollowerComponent.TotalDistance = 0.f;
		NiagaraComponent.SetNiagaraVariableFloat("SpawnRate", 0.f);

		BSLeanValue = 0.f;
		BSSpeed = 0.f;

		MovementComp.Reset();

		// Rotation might be wrong here !!!
		SetActorLocationAndRotation(SplineFollowerComponent.Transform.Location, SplineFollowerComponent.SplineTransform.Rotation);
	}

	UFUNCTION(NetFunction)
	void NetStopSnowfolk(UConnectedHeightSplineComponent Spline, float Distance, float Offset)
	{
		PrintScaled("NetStopSnowfolk", 2.f, FLinearColor::Green, 2.f);
		SplineFollowerComponent.Spline = Spline;
		SplineFollowerComponent.SetDistanceAndOffset(Distance, Offset);

		//Speed = 0.f;
		MovementComp.Speed = 0.f;
	}

	UFUNCTION(NetFunction)
	void NetResumeSnowfolk(UConnectedHeightSplineComponent Spline, float Distance, float Offset)
	{
		SplineFollowerComponent.Spline = Spline;
		SplineFollowerComponent.SetDistanceAndOffset(Distance, Offset);

		//Speed = BaseSpeed;
		MovementComp.Speed = MovementComp.BaseSpeed;
	}
	
	UFUNCTION(BlueprintEvent)
	void BP_PlayerBounce(AHazePlayerCharacter Player) {}

	UFUNCTION()
	void DrawDebug()
	{
		System::DrawDebugLine(ActorLocation, ActorLocation + SplineFollowerComponent.Velocity * 1.f, FLinearColor::Red, 0.f, 30.f);
		System::DrawDebugLine(ActorLocation, ActorLocation + ActorUpVector * 1000.f, FLinearColor::Blue, 0.f, 20.f);
		System::DrawDebugLine(ActorLocation, ActorLocation + ActorRightVector * 1000.f, FLinearColor::Green, 0.f, 20.f);
		System::DrawDebugLine(ActorLocation, ActorLocation + SplineFollowerComponent.AngularVelocity * 200.f, FLinearColor::Yellow, 0.f, 30.f);

		//PrintToScreen("Speed: " + Speed);
		PrintToScreen("BSSpeed: " + BSSpeed);
		PrintToScreen("BSLeanValue: " + BSLeanValue);
		//PrintToScreen("ExtraOffset: " + ExtraOffset);
		PrintToScreen("Velocity: " + SplineFollowerComponent.Velocity.Size());
		PrintToScreen("AngularVelocity: " + SplineFollowerComponent.AngularVelocity);
	}

	void UpdateDetailLevel()
	{
		if (!bIsSnowfolkActivated)
		{
			SetSnowfolkDetailLevel(ESnowFolkDetailLevel::Hidden);
			return;
		}

		const FVector Location = SplineFollowerComponent.Transform.Location;

		// Check if this snowfolk is seen by any player, in which case we want to completely hide them (not even update the LOD mesh)
		bool bIsSeen = false;
		for(auto Player : Game::Players)
		{
			if(SceneView::ViewFrustumPointRadiusIntersection(Player, Location, 900.f))
				bIsSeen = true;
		}

		if (!bIsSeen)
		{
			SetSnowfolkDetailLevel(ESnowFolkDetailLevel::Hidden);
			return;
		}

		// After that, check if we're far enough away from a camera to become lodded into a static mesh
		TPerPlayer<float> CameraDistance;
		for(auto Player : Game::Players)
			CameraDistance[Player.Player] = (Player.GetViewLocation() - Location).SizeSquared();

		// The closest camera sets the detail level
		float MinDistanceSq = FMath::Min(CameraDistance[0], CameraDistance[1]);
		if (MinDistanceSq > FMath::Square(LodDistance))
		{
			SetSnowfolkDetailLevel(ESnowFolkDetailLevel::Lodded);
			return;
		}

		// Otherwise, we're visible ITS GO TIME BABY
		SetSnowfolkDetailLevel(ESnowFolkDetailLevel::Visible);
	}

	UFUNCTION()
	void ActivateSnowfolk()
	{
		if (bIsSnowfolkActivated)
			return;

		SplineFollowerComponent.Transform = ActorTransform;

		bIsSnowfolkActivated = true;
		RemoveDisableTag(n"Activation");

		PatrolAudioComp.BP_RegisterToManager();
		OnSnowfolkEnabled.Broadcast();
	}

	UFUNCTION()
	void DeactivateSnowfolk()
	{
		if (!bIsSnowfolkActivated)
			return;

		bIsSnowfolkActivated = false;
		AddDisableTag(n"Activation");

		PatrolAudioComp.BP_UnregisterToManager();
		OnSnowFolkDisabled.Broadcast();
	}

	void ShowSnowfolk()
	{
		if (bIsSnowfolkVisible)
			return;

		bIsSnowfolkVisible = true;
		RemoveDisableTag(n"Hidden");
	}

	void HideSnowfolk()
	{
		if (!bIsSnowfolkVisible)
			return;

		bIsSnowfolkVisible = false;

		// StopAllSlotAnimations(0.f);

		AddDisableTag(n"Hidden");
	}

	void AddDisableTag(FName Tag)
	{
		if (DisableTags.Num() == 0)
		{
			DisableActor(this);

			// Disable all attached actors (hats)
			TArray<AActor> Children;
			GetAttachedActors(Children);

			for(auto Child : Children)
			{
				auto HazeChild = Cast<AHazeActor>(Child);
				if (HazeChild == nullptr)
					continue;

				HazeChild.DisableActor(this);
			}
		}

		ensure(!DisableTags.Contains(Tag));
		DisableTags.Add(Tag);
	}

	void RemoveDisableTag(FName Tag)
	{
		ensure(DisableTags.Contains(Tag));
		DisableTags.Remove(Tag);

		if (DisableTags.Num() == 0)
		{
			EnableActor(this);

			// Enable all attached actors (hats)
			TArray<AActor> Children;
			GetAttachedActors(Children);

			for(auto Child : Children)
			{
				auto HazeChild = Cast<AHazeActor>(Child);
				if (HazeChild == nullptr)
					continue;

				// This child might've been attached after we disabled
				// in which case it would've missed the initial disable
				if (HazeChild.IsActorDisabled(this))
					HazeChild.EnableActor(this);
			}

			// Snap to the current target transform
			FTransform CurrentTransform = MovementComp.GetCurrentTransform();
			SetActorLocationAndRotation(CurrentTransform.Location, CurrentTransform.Rotation);
		}
	}
}