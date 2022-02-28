import Peanuts.Spline.SplineComponent;
import Peanuts.Triggers.ActorTrigger;

event void FOnTownsfolkReachedEndOfSpline(ATownsfolkActor Townsfolk);
event void FOnTownsfolkStoppedAtBlocker(ATownsfolkActor Townsfolk, ATownsfolkBlocker Blocker);
event void FOnTownsfolkEnteredTrigger(ATownsfolkActor Townsfolk, ATownsfolkTrigger Trigger);
event void FOnTownsfolkExitTrigger(ATownsfolkActor Townsfolk, ATownsfolkTrigger Trigger);

class ATownsfolkActor : AHazeActor
{
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostPhysics;
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent PlayerCollision;
	default PlayerCollision.RelativeLocation = FVector(0.f, 0.f, 125.f);
	default PlayerCollision.CapsuleHalfHeight = 180.f;
	default PlayerCollision.CapsuleRadius = 55.f;
	default PlayerCollision.CollisionProfileName = n"BlockOnlyPlayerCharacter";
	default PlayerCollision.RemoveTag(n"Walkable");
	default PlayerCollision.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkelMesh;
	default SkelMesh.bComponentUseFixedSkelBounds = true;
	default SkelMesh.bGenerateOverlapEvents = false;
	default SkelMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default SkelMesh.AnimationMode = EAnimationMode::AnimationBlueprint;
	default SkelMesh.AnimClass = Asset("/Game/Blueprints/LevelSpecific/Clockwork/Townsfolk/ABP_ClockworkTownsfolk.ABP_ClockworkTownsfolk_C");
	default SkelMesh.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::OnlyTickPoseWhenRendered;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Platform;
	default Platform.RelativeLocation = FVector(0.f, 0.f, 4.f);
	default Platform.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Box;
	default Box.GenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 8000.f;

	UPROPERTY(DefaultComponent)
	UHazeSplineFollowComponent SplineFollow;

	UPROPERTY()
	FOnTownsfolkReachedEndOfSpline OnReachedEndOfSpline;

	UPROPERTY()
	FOnTownsfolkStoppedAtBlocker OnTownsfolkStoppedAtBlocker;

	UPROPERTY(Category = "Townsfolk")
	float WalkSpeed = 500.f;

	UPROPERTY(Category = "Townsfolk")
	AActor StartingSpline;

	UPROPERTY(Category = "Townsfolk")
	bool bMovingForward = true;

	UPROPERTY(Category = "Townsfolk")
	bool bActiveFromStart = true;

	UPROPERTY(Category = "Townsfolk")
	bool bFaceForward = true;

	UPROPERTY(Category = "Townsfolk")
	bool bAlwaysFaceMovementDirection = true;

	UPROPERTY(Category = "Overlaps")
	bool bNeedOverlaps = true;

	UPROPERTY(Category = "Overlaps", meta = (EditCondition = "bNeedOverlaps"))
	bool bUseBlockers = true;

	bool bPlayedMovementSound = false;

	UPROPERTY(Category = "Townsfolk")
	UAnimSequence MovingAdditiveAnimation = Asset("AnimSequence'/Game/Animations/Characters/NPC/ClockWork/NPC_ClockWork_Generic_Move.NPC_ClockWork_Generic_Move'");

	/** Fill this with the potential blockers to evaluate. */
	UPROPERTY(Category = "Overlaps", EditInstanceOnly, meta = (EditCondition = "bUseBlockers && bNeedOverlaps", EditConditionHides))
	TArray<ATownsfolkBlocker> PotentialOverlappingBlockers;

	UPROPERTY(Category = "Overlaps", meta = (EditCondition = "bNeedOverlaps"))
	bool bUseTriggers = true;

	/** Fill this with the potential triggers to evaluate. */
	UPROPERTY(Category = "Overlaps", EditInstanceOnly, meta = (EditCondition = "bUseTriggers && bNeedOverlaps", EditConditionHides))
	TArray<AActorTrigger> PotentialTriggers;

	/** Fill this with the potential triggers to evaluate. */
	UPROPERTY(Category = "Overlaps", EditInstanceOnly, meta = (EditCondition = "bUseTriggers && bNeedOverlaps", EditConditionHides))
	TArray<ATownsfolkTrigger> PotentialActorTriggers;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent MovementEvent;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector TownsfolkVelocity;

	private ATownsfolkBlocker CurrentBlocker;
	private bool bShouldMove = false;
	private bool bReachedEndOfSpline = false;
	private bool bMovedPreviousFrame = false;
	private TArray<AActorTrigger> CheckBeginOverlapTriggers;
	private TArray<AActorTrigger> CheckEndOverlapTriggers;
	private TArray<ATownsfolkTrigger> CheckBeginOverlapActorTriggers;
	private TArray<ATownsfolkTrigger> CheckEndOverlapActorTriggers;
	private UHazeCrumbComponent CrumbComp;
	private FHazeAudioEventInstance MovementEventInstance;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SkelMesh.SetCullDistance(Editor::GetDefaultCullingDistance(SkelMesh) * CullDistanceMultiplier);
		Platform.SetCullDistance(Editor::GetDefaultCullingDistance(Platform) * CullDistanceMultiplier);
	}

	UFUNCTION()
	void StartMovingOnSpline(AActor SplineActor, bool bSnapToStartOfSpline = false, bool bForwardOnSpline = true)
	{
		auto SplineComp = UHazeSplineComponentBase::Get(SplineActor);

		FHazeSplineSystemPosition StartPosition;
		if (bSnapToStartOfSpline)
			StartPosition = SplineComp.GetPositionAtStart(bForwardOnSpline);
		else
			StartPosition = SplineComp.GetPositionClosestToWorldLocation(ActorLocation, bForwardOnSpline);

		if (SplineFollow.HasActiveSpline())
			SplineFollow.DeactivateSplineMovement();
		SplineFollow.ActivateSplineMovement(StartPosition);

		ActorTransform = SplineFollow.Position.GetWorldTransform();
		bShouldMove = true;
		if (!IsActorDisabled())
			SetActorTickEnabled(true);	

		if(!bPlayedMovementSound)
		{
			MovementEventInstance = HazeAkComp.HazePostEvent(MovementEvent);
			HazeAkComp.SeekOnPlayingEvent(MovementEvent, MovementEventInstance.PlayingID, 1, true, true, false);
			bPlayedMovementSound = true;
		}
	}

	UFUNCTION()
	void ReverseMoveDirection()
	{
		SplineFollow.Reverse();
	}

	UFUNCTION()
	void StopMoving()
	{
		bShouldMove = false;

		if(bPlayedMovementSound)
		{
			HazeAkComp.HazeStopEventInstance(MovementEventInstance, 100.f);	
			bPlayedMovementSound = false;
		}
	}

	UFUNCTION()
	void ResumeMoving()
	{
		bShouldMove = true;
		if (!IsActorDisabled())
			SetActorTickEnabled(true);		
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CrumbComp = UHazeCrumbComponent::Get(this);
		if (CrumbComp != nullptr)
			SplineFollow.IncludeSplineInActorReplication(this);

		if (StartingSpline != nullptr && bActiveFromStart)
		{
			StartMovingOnSpline(StartingSpline, bForwardOnSpline = bMovingForward);
		}

		// If we're already inside a blocker, apply it
		if (bNeedOverlaps)
		{

		#if EDITOR
			if(PotentialOverlappingBlockers.Num() == 0 && bUseBlockers)
			{
				Log("Townsfolk: " + GetName() + " wants Blockers but dont have any. Disable the NeedOverlaps or UseBlockers or add PotentialOverlappingBlockers");
				devEnsure(false);
			}

			// TEMP
			GetAllActorsOfClass(ATownsfolkTrigger::StaticClass(), PotentialActorTriggers);	
			
			if(PotentialTriggers.Num() == 0 && PotentialActorTriggers.Num() == 0 && bUseTriggers)
			{
				Log("Townsfolk: " + GetName() + " wants Triggers but dont have any. Disable the NeedOverlaps or UseTriggers or add PotentialTriggers");
				devEnsure(false);
			}
		#endif
				
			CheckBeginOverlapTriggers = PotentialTriggers;
			CheckBeginOverlapActorTriggers = PotentialActorTriggers;
			UpdateActorOverlaps();
		}
	}

	UFUNCTION(NetFunction)
	private void NetBroadcastReachedEndOfSpline()
	{
		OnReachedEndOfSpline.Broadcast(this);
		HazeAkComp.HazeStopEventInstance(MovementEventInstance, 100.f);	
		bPlayedMovementSound = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		bool bMovedThisFrame = false;
		if (bShouldMove)
		{
			// Only proceed if we're not being blocked
			if (CrumbComp != nullptr && !HasControl())
			{
				FHazeActorReplicationFinalized ReplicationFinalized;
				CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ReplicationFinalized);
				SplineFollow.UpdateReplicatedSplineMovement(ReplicationFinalized);

				bMovedThisFrame = !ReplicationFinalized.DeltaTranslation.IsNearlyZero();
			}
			else if (CurrentBlocker == nullptr)
			{
				FHazeSplineSystemPosition NewPosition;

				auto Result = SplineFollow.UpdateSplineMovement(DeltaTime * WalkSpeed, NewPosition);

				if (Result != EHazeUpdateSplineStatusType::AtEnd)
				{
					// We're continuing to move along the spline
					bReachedEndOfSpline = false;
					bMovedThisFrame = true;
				}
				else
				{
					// End of the spline has been reached
					if (!bReachedEndOfSpline)
					{
						if (CrumbComp != nullptr)
							NetBroadcastReachedEndOfSpline();
						else
							OnReachedEndOfSpline.Broadcast(this);
						bReachedEndOfSpline = true;
						bMovedThisFrame = true;
					}
				}
			}

			// Still update position from the spline if it can move
			if (SplineFollow.ActiveSpline != nullptr && (bMovedThisFrame || SplineFollow.ActiveSpline.Owner.RootComponent.Mobility == EComponentMobility::Movable))
			{
				FTransform Transform = SplineFollow.Position.GetWorldTransform();

				if (!bAlwaysFaceMovementDirection)
				{
					FRotator Rotation = SplineFollow.Position.Spline.GetDirectionAtDistanceAlongSpline(SplineFollow.Position.DistanceAlongSpline, ESplineCoordinateSpace::World).Rotation();
					if (!bFaceForward)
					{
						FVector ReverseDir = -SplineFollow.Position.Spline.GetDirectionAtDistanceAlongSpline(SplineFollow.Position.DistanceAlongSpline, ESplineCoordinateSpace::World);
						Rotation = ReverseDir.Rotation();
					}
					Transform.Rotation = FQuat(Rotation);
				}

				FVector PrevLocation = ActorLocation;
				SetActorTransform(Transform);
				if (DeltaTime > 0.f)
					TownsfolkVelocity = (ActorLocation - PrevLocation) / DeltaTime;
			}

			 if (bMovedThisFrame && HasControl() && CrumbComp != nullptr)
				 CrumbComp.LeaveMovementCrumb();
		}

		if (!bMovedPreviousFrame && bMovedThisFrame)
		{
			BP_StartedMoving();
			if (MovingAdditiveAnimation != nullptr)
				PlayAdditiveAnimation(FHazeAnimationDelegate(), MovingAdditiveAnimation, bLoop = true);

			if(!bPlayedMovementSound)
			{
				MovementEventInstance = HazeAkComp.HazePostEvent(MovementEvent);
				HazeAkComp.SeekOnPlayingEvent(MovementEvent, MovementEventInstance.PlayingID, 1, true, true, false);
				bPlayedMovementSound = true;
			}
		}
		else if (bMovedPreviousFrame && !bMovedThisFrame)
		{
			TownsfolkVelocity = FVector::ZeroVector;
			BP_StoppedMoving();
			if (MovingAdditiveAnimation != nullptr)
				StopAdditiveAnimation(MovingAdditiveAnimation);

			if(bPlayedMovementSound)
			{
				HazeAkComp.HazeStopEventInstance(MovementEventInstance, 100.f);
				bPlayedMovementSound = false;		
			}
		}
		
		bMovedPreviousFrame = bMovedThisFrame;

		if(bNeedOverlaps)
			UpdateActorOverlaps();

		if (!bShouldMove)
			SetActorTickEnabled(false);
	}

	void UpdateActorOverlaps()
	{
		if(bUseBlockers)
		{
			if(CurrentBlocker != nullptr)
			{
				if(!ValidateBlocker(CurrentBlocker))
					CurrentBlocker = nullptr;	
			}

			// If we have a current blocker, we dont need to evaluate any other blockers
			if(CurrentBlocker == nullptr)
			{
				for(auto Blocker : PotentialOverlappingBlockers)
				{
					if (Blocker == nullptr)
						continue;

					if(ValidateBlocker(Blocker))
					{
						// Call events on both actors
						CurrentBlocker = Blocker;
						OnTownsfolkStoppedAtBlocker.Broadcast(this, Blocker);
						Blocker.OnTownsfolkStoppedAtBlocker.Broadcast(this, Blocker);
						SetCapabilityActionState(n"AudioStoppedAtBlocker", EHazeActionState::ActiveForOneFrame);
						break;
					}
				}
			}
		}

		if(bUseTriggers)
		{	
			// Triggers
			{
				// We can skip all the newly added shapes in the next array
				int SkipEndOverlapAmount = 1;
				for(int i = CheckBeginOverlapTriggers.Num() - 1; i >= 0; --i)
				{
					auto Trigger = CheckBeginOverlapTriggers[i];
					if (Trigger == nullptr)
						continue;

					if(!Trigger.IsOverlappingShape(Box))
						continue;

					Trigger.ActorBeginOverlap(this);
					CheckBeginOverlapTriggers.RemoveAtSwap(i);
					CheckEndOverlapTriggers.Add(Trigger);
					SkipEndOverlapAmount++;
				}

				for(int i = CheckEndOverlapTriggers.Num() - SkipEndOverlapAmount; i >= 0; --i)
				{
					auto Trigger = CheckEndOverlapTriggers[i];
					if (Trigger == nullptr)
						continue;

					if(Trigger.IsOverlappingShape(Box))
						continue;

					Trigger.ActorEndOverlap(this);
					CheckEndOverlapTriggers.RemoveAtSwap(i);
					CheckBeginOverlapTriggers.Add(Trigger);
				}
			}
		
			// Actor Triggers
			{
				int SkipEndOverlapAmount = 1;
				for(int i = CheckBeginOverlapActorTriggers.Num() - 1; i >= 0; --i)
				{
					auto Trigger = CheckBeginOverlapActorTriggers[i];
					if (Trigger == nullptr)
						continue;

					if(!Trigger.IsOverlappingShape(Box))
						continue;

					Trigger.OverlapBeginWith(this);
					CheckBeginOverlapActorTriggers.RemoveAtSwap(i);
					CheckEndOverlapActorTriggers.Add(Trigger);
					SkipEndOverlapAmount++;
				}
				
				for(int i = CheckEndOverlapActorTriggers.Num() - SkipEndOverlapAmount; i >= 0; --i)
				{
					auto Trigger = CheckEndOverlapActorTriggers[i];
					if (Trigger == nullptr)
						continue;

					if(Trigger.IsOverlappingShape(Box))
						continue;

					Trigger.OverlapEndWith(this);
					CheckEndOverlapActorTriggers.RemoveAtSwap(i);
					CheckBeginOverlapActorTriggers.Add(Trigger);
				}
			}		
		}
	}

	bool ValidateBlocker(ATownsfolkBlocker Blocker) const
	{
		if(!Blocker.IsBlockerEnabled())
			return false;

		float Distance = Blocker.Box.GetWorldLocation().DistSquared(Box.GetWorldLocation());
		float PossibleCollisionSize = FMath::Square(Blocker.Box.GetScaledBoxExtent().Size() * 3) + (Box.GetScaledBoxExtent().Size() * 3);
		if(Distance > PossibleCollisionSize)
			return false;

		return Trace::ComponentOverlapComponent(
			Box,
			Blocker.Box,
			Blocker.Box.WorldLocation,
			Blocker.Box.ComponentQuat,
			bTraceComplex = false
		);
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartedMoving() {}

	UFUNCTION(BlueprintEvent)
	void BP_StoppedMoving() {}
};

class ATownsfolkBlocker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent Box;
	default Box.bGenerateOverlapEvents = false;

	UPROPERTY(Category = "Townsfolk Blocker")
	bool bBlockerEnabled = true;

	UPROPERTY()
	FOnTownsfolkStoppedAtBlocker OnTownsfolkStoppedAtBlocker;

	UFUNCTION(BlueprintPure)
	bool IsBlockerEnabled()
	{
		return bBlockerEnabled;
	}

	UFUNCTION()
	void DisableBlocker()
	{
		bBlockerEnabled = false;
	}

	UFUNCTION()
	void EnableBlocker()
	{
		bBlockerEnabled = true;
	}
};


class ATownsfolkTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Trigger;
	default Trigger.bGenerateOverlapEvents = false;

	UPROPERTY(Category = "Activation", EditInstanceOnly)
	bool bTriggerEnabled = true;

	UPROPERTY(Category = Events)
	FOnTownsfolkEnteredTrigger OnTownfolkEnter;

	UPROPERTY()
	FOnTownsfolkExitTrigger OnTownfolkExit;

	void OverlapBeginWith(ATownsfolkActor Townsfolk)
	{	
// #if TEST
// 		Log("" + GetName() + " | OverlapBeginWith: " + Townsfolk.GetName() + " Control: " + Townsfolk.HasControl());
// #endif

		OnTownfolkEnter.Broadcast(Townsfolk, this);
		BP_OnTownfolkEnter(Townsfolk);
	}

	void OverlapEndWith(ATownsfolkActor Townsfolk)
	{
// #if TEST
// 		Log("" + GetName() + " | OverlapEndWith: " + Townsfolk.GetName() + " Control: " + Townsfolk.HasControl());
// #endif

		OnTownfolkExit.Broadcast(Townsfolk, this);
		BP_OnTownfolkExit(Townsfolk);
	}

	UFUNCTION(BlueprintPure)
	bool IsBlockerEnabled()
	{
		return bTriggerEnabled;
	}

	UFUNCTION()
	void DisableBlocker()
	{
		bTriggerEnabled = false;
	}

	UFUNCTION()
	void EnableBlocker()
	{
		bTriggerEnabled = true;
	}

	bool IsOverlappingShape(UShapeComponent Shape) const
	{
		if(!bTriggerEnabled)
			return false;

		if(!Trigger.IsCollisionEnabled())
			return false;

		float DistSq = Shape.GetWorldLocation().DistSquared(Trigger.GetWorldLocation());
		float ShapeCollisionSize = GetShapeCollisionSize(Shape);
		float TriggerCollisionSize = GetShapeCollisionSize(Trigger.GetCollisionShape());
	
		if(DistSq > FMath::Square((ShapeCollisionSize + TriggerCollisionSize) * 2))
			return false;

		return Trace::ComponentOverlapComponent(
			Shape,
			Trigger,
			Trigger.WorldLocation,
			Trigger.ComponentQuat,
			bTraceComplex = false
		);
	}

	private float GetShapeCollisionSize(UShapeComponent Shape) const
	{
		auto Box = Cast<UBoxComponent>(Shape);
		if(Box != nullptr)
		{
			FVector Extends = Box.GetScaledBoxExtent();
			return FMath::Max(Extends.X, FMath::Max(Extends.Y, Extends.Z));
		}

		auto Sphere = Cast<USphereComponent>(Shape);
		if(Sphere != nullptr)
		{
			return Sphere.GetScaledSphereRadius();
		}

		auto Capsule = Cast<UCapsuleComponent>(Shape);
		if(Capsule != nullptr)
		{
			return Capsule.GetScaledCapsuleHalfHeight();
		}

		return 0;
	}

	private float GetShapeCollisionSize(FCollisionShape Shape) const
	{
		FVector Extends = Shape.GetExtent();
		return FMath::Max(Extends.X, FMath::Max(Extends.Y, Extends.Z));
	}

	UFUNCTION(BlueprintEvent)
	protected void BP_OnTownfolkEnter(ATownsfolkActor Townsfolk) {}

	UFUNCTION(BlueprintEvent)
	protected void BP_OnTownfolkExit(ATownsfolkActor Townsfolk) {}

#if EDITOR
	/** This will convert any found box collisions into all the found ATownsfolkTrigger actors */
	UFUNCTION(CallInEditor, Category = "EDITOR ONLY")
	void ConvertAllActors()
	{
		TArray<ATownsfolkTrigger> ActorTriggers;
		GetAllActorsOfClass(ActorTriggers);
		for(auto ActorTrigger : ActorTriggers)
		{
			ActorTrigger.ConvertBoxCollisionInternal();
		}
	}

	/** This will convert any found box collisions into the Trigger component */
	UFUNCTION(CallInEditor, Category = "EDITOR ONLY")
	void ConvertThisActorOnly()
	{
		ConvertBoxCollisionInternal();
	}

	void ConvertBoxCollisionInternal()
	{
		TArray<UActorComponent> FoundComponents;
		GetAllComponents(UBoxComponent::StaticClass(), FoundComponents);

		for(int i = 0; i < FoundComponents.Num(); ++i)
		{
			UBoxComponent BoxIndex = Cast<UBoxComponent>(FoundComponents[i]);
			if(BoxIndex == Trigger)
				continue;

			if(BoxIndex.Owner != this)
				continue;

			Trigger.SetRelativeTransform(BoxIndex.GetRelativeTransform());
			Trigger.BoxExtent = BoxIndex.BoxExtent;
			// Trigger.LineThickness = BoxIndex.LineThickness + 10;
			// Shape::SetShapeColor(Trigger, BoxIndex.ShapeColor);
			break;
		}
	}
	
#endif
};