import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.Tree.Rails.TreeRailCartHatch;

enum ETreeRailCartMoveType
{
	None,
	FollowParent,
	Active,
	ActiveWrapAtEnd,
	Detached
}

class UTreeRailCartMover : USceneComponent
{
	// Make sure that we are ticking before gameplay and after the player has moved
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_HazeAnimation;

	UPROPERTY(Transient, EditConst)
	ETreeRailCartMoveType CurrentMoveType = ETreeRailCartMoveType::None;

	UPROPERTY(Transient, EditConst)
	bool bHasDeactivatedActor = false;

	UPROPERTY(Transient, EditConst)
	bool bHasStartedTicking = false;

	// The component we are following
	UPROPERTY(Transient)
	UTreeRailCartMover ParentMover;

	const FVector GravityForce = FVector(0.f, 0.f, -980.f);
	const float ForceAmount = 0.f;
	const float DragAmount = 0.1f;

	ATreeRailCart OwnerCart;
	UHazeSplineFollowComponent SplineComponent;
	EHazeUpdateSplineStatusType SplineFollowMovementStatus = EHazeUpdateSplineStatusType::Invalid;
	float MovementMultiplier = 1.f;

	bool bApplyForces = false;
	float CurrentSpeed = 0;
	FVector CurrentDetachVelocity;
	FTransform CurrentTransformOnSpline;
	float ForceStepAmountToAdd = 0;
	float LastMovedAmount = 0;
	float DistanceToKeepToParent = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OwnerCart = Cast<ATreeRailCart>(Owner);
		bHasDeactivatedActor = true;
		OwnerCart.DisableActor(this);
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		// Never disable
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(CurrentMoveType != ETreeRailCartMoveType::None)
		{	
			UpdateMovement(DeltaSeconds);	
			OwnerCart.UpdateOverlapsAndVisibility();
			OwnerCart.UpdateAudio(CurrentTransformOnSpline);

			if(OwnerCart.bHazeEditorOnlyDebugBool)
			{
				System::DrawDebugSphere(OwnerCart.GetActorLocation(), 800.f);
				for(auto Child : OwnerCart.FollowingCarts)
				{
					System::DrawDebugArrow(OwnerCart.GetActorLocation(), Child.GetActorLocation());
				}
			}
		}
		else
		{
			bHasStartedTicking = false;
			SetComponentTickEnabled(false);
			OwnerCart.bAnyPlayerCanSee = false;
		}

		if(!bHasDeactivatedActor && (!OwnerCart.bAnyPlayerCanSee || CurrentMoveType == ETreeRailCartMoveType::None))
		{
			bHasDeactivatedActor = true;
			OwnerCart.DisableActor(this);
		}
		else if(bHasDeactivatedActor && OwnerCart.bAnyPlayerCanSee)
		{
			bHasDeactivatedActor = false;
			OwnerCart.EnableActor(this);
		}
	}

	// We can't use this if we want the carts to stay on the same location from eachother
	// float CalculateForce(float DeltaTime) const
	// {
	// 	float FinalForce = ForceAmount;
	// 	FinalForce += CurrentTransformOnSpline.GetRotation().ForwardVector.DotProduct(GravityForce);
	// 	FinalForce -= (CurrentSpeed * DragAmount);
	// 	FinalForce *= DeltaTime;
	// 	return FinalForce;
	// }

	void UpdateMovement(float DeltaSeconds)
	{
		if(CurrentMoveType == ETreeRailCartMoveType::Detached)
		{
			FVector DetachVelocityAcc = GravityForce - (CurrentDetachVelocity * DragAmount);
			DetachVelocityAcc *= DeltaSeconds;
			CurrentTransformOnSpline.AddToTranslation(CurrentDetachVelocity);

			// Always update the acceleration for next frame so the first frame uses the current velocity
			CurrentDetachVelocity += DetachVelocityAcc;
		}
		// If we follow the parent, the parent will update us
		else if(CurrentMoveType == ETreeRailCartMoveType::FollowParent)
		{
			ensure(ParentMover != nullptr);
			const float MoveAmount = ParentMover.LastMovedAmount * MovementMultiplier;
			ApplySplineMoveAmount(MoveAmount);
		}
		else
		{
			// The drag makes the wagons positions offset from eachother
			// Removed for now.
			// if(bApplyForces)
			// {
			// 	CurrentSpeed += CalculateForce(DeltaSeconds);
			// }
	
			const float MoveAmount = CurrentSpeed * DeltaSeconds;
			ApplySplineMoveAmount(MoveAmount);
		}
	}

	void ApplySplineMoveAmount(float MoveAmount)
	{
		LastMovedAmount = MoveAmount;
		FHazeSplineSystemPosition CurrentSplinePosition;
		bool bWarped = false;
		if(CurrentMoveType == ETreeRailCartMoveType::ActiveWrapAtEnd)
		{
			SplineFollowMovementStatus = SplineComponent.UpdateSplineMovementAndRestartAtEnd(MoveAmount, CurrentSplinePosition, bWarped);
			CurrentTransformOnSpline = CurrentSplinePosition.GetWorldTransform();
		}
		else if(CurrentMoveType == ETreeRailCartMoveType::FollowParent)
		{
			SplineFollowMovementStatus = SplineComponent.UpdateSplineMovementAndRestartAtEnd(MoveAmount, CurrentSplinePosition, bWarped);
			CurrentTransformOnSpline = CurrentSplinePosition.GetWorldTransform();
			if(bWarped)
			{
				EHazeUpdateSplineStatusType PositionStatus = EHazeUpdateSplineStatusType::Invalid;
				FHazeSplineSystemPosition ParentPosition = ParentMover.SplineComponent.GetPosition(PositionStatus);
				if(PositionStatus != EHazeUpdateSplineStatusType::Invalid)
				{
					float Offset = ParentPosition.DistanceAlongSpline - CurrentSplinePosition.DistanceAlongSpline;
					float Diff = DistanceToKeepToParent - Offset;
					if(Diff > 0)
						SplineComponent.UpdateSplineMovement(Diff, CurrentSplinePosition);
				}
			}
		}
		else
		{
			SplineFollowMovementStatus = SplineComponent.UpdateSplineMovement(MoveAmount, CurrentSplinePosition);
			CurrentTransformOnSpline = CurrentSplinePosition.GetWorldTransform();

			if(SplineFollowMovementStatus != EHazeUpdateSplineStatusType::Valid)
			{
				CurrentMoveType = ETreeRailCartMoveType::Detached;
				CurrentDetachVelocity = CurrentSplinePosition.GetWorldForwardVector() * CurrentSpeed;
				SplineFollowMovementStatus = EHazeUpdateSplineStatusType::Invalid;

				// Detach all the followers
				for(auto ChildCart : OwnerCart.FollowingCarts)
				{
					ChildCart.RailCartMover.CurrentMoveType = CurrentMoveType;
					ChildCart.RailCartMover.CurrentDetachVelocity = CurrentDetachVelocity;
					ChildCart.RailCartMover.ParentMover = nullptr;
				}

				OwnerCart.FollowingCarts.Reset();
			}
		}
	}

	void ActivateMovement(ETreeRailCartMoveType Type)
	{
		if(Type != ETreeRailCartMoveType::None)
		{
			CurrentMoveType = Type;
			bHasStartedTicking = true;
			SetComponentTickEnabled(true);
		}
	}

	void DeactivateMovement()
	{
		CurrentMoveType = ETreeRailCartMoveType::None;
	}
}

UCLASS(Abstract)
class ATreeRailCart : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeSplineFollowComponent SplineFollow;
	default SplineFollow.PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	UTreeRailCartMover RailCartMover;
	default RailCartMover.SplineComponent = SplineFollow;
	default RailCartMover.PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, Attach = RailCartMover)
	UHazeStaticMeshComponent Mesh;
	default Mesh.SetCollisionProfileName(n"NoCollision");
	default Mesh.ShadowPriority = EShadowPriority::GameplayElement;

	UPROPERTY(DefaultComponent)
	UBoxComponent PlayerOverlapTrigger;
	default PlayerOverlapTrigger.RelativeLocation = FVector(0.f, 0.f, 150.f);
	default PlayerOverlapTrigger.BoxExtent = FVector(200, 100, 200);
	default PlayerOverlapTrigger.bGenerateOverlapEvents = false;
	default PlayerOverlapTrigger.CanCharacterStepUpOn = ECanBeCharacterBase::ECB_No;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComponent;
	default HazeAkComponent.RelativeLocation = FVector(150.f, 0.f, 200.f);
	default HazeAkComponent.RelativeRotation = FRotator(0.f, 180.f, 0.f);
	default HazeAkComponent.bLinkToAmbientZone = true;
	
	UPROPERTY(EditConst)
	TArray<FHatchData> OverlappableHatches;
	int IsOverlappingHatchIndex = -1;

	UPROPERTY(EditConst, Transient)
	TArray<ATreeRailCart> FollowingCarts;

	bool bAnyPlayerCanSee = false;
	bool bHasResetAudioPos = false;
	AHazePlayerCharacter LastPlayerThatCouldSee;
	FTransform OriginalRelativeAudioTransform;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalRelativeAudioTransform = HazeAkComponent.GetRelativeTransform();
	}
	
	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(IsOverlappingHatchIndex >= 0)
		{
			if(OverlappableHatches[IsOverlappingHatchIndex].Hatch != nullptr)
				OverlappableHatches[IsOverlappingHatchIndex].Hatch.RemoveOverlappingCart(this);
			IsOverlappingHatchIndex = -1;

		}

		RailCartMover.DeactivateMovement();
	}

	UFUNCTION(CallInEditor)
	void CollectHatchesOnTheSameTrack()
	{
		TArray<ATreeRailCart> CartsInLevel;
		GetAllActorsOfClass(CartsInLevel);

		TArray<ATreeRailCartHatch> HatchesInLevel;
		GetAllActorsOfClass(HatchesInLevel);

		for(auto Cart : CartsInLevel)
		{
			Cart.CollectHatchesOnTheSameTrackInternal(HatchesInLevel);
		}
	}

	void CollectHatchesOnTheSameTrackInternal(TArray<ATreeRailCartHatch> HatchesInLevel)
	{
		OverlappableHatches.Reset();

		for(auto Hatch : HatchesInLevel)
		{
			FHatchCollectStatus Status = ValidateHatch(Hatch);
			if(Status.bIsValidHatch)
			{
				FHatchData NewEntry;
				NewEntry.Hatch = Hatch;
				NewEntry.bIsEnteringHatch = Status.bIsEnteringHatch;
				OverlappableHatches.Add(NewEntry);
			}	
		}
	}

	UFUNCTION(BlueprintEvent)
	FHatchCollectStatus ValidateHatch(ATreeRailCartHatch Hatch) 
	{
		FHatchCollectStatus InvalidStatus;
		return InvalidStatus;
	}

	void UpdateOverlapsAndVisibility()
	{
		auto Cody = Game::Cody;
		auto May = Game::May;
		const bool bCouldSee = bAnyPlayerCanSee;

		FVector CurrentSplineLocation = RailCartMover.CurrentTransformOnSpline.GetLocation();
		const float DistanceToCody = CurrentSplineLocation.DistSquared(Cody.GetActorLocation());
		const float DistanceToMay = CurrentSplineLocation.DistSquared(May.GetActorLocation());

		float ClosestDistance;
		AHazePlayerCharacter ClosestPlayer;
		if(DistanceToCody < DistanceToMay)
		{
			ClosestPlayer = Cody;
			ClosestDistance = DistanceToCody;
		}
		else
		{
			ClosestPlayer = May;
			ClosestDistance = DistanceToMay;
		}

		if(LastPlayerThatCouldSee == nullptr)
			LastPlayerThatCouldSee = ClosestPlayer;

		if (ClosestDistance < FMath::Square(5000.f))
		{	
			if(Trace::ComponentOverlapComponent(
				ClosestPlayer.CapsuleComponent,
				PlayerOverlapTrigger,
				PlayerOverlapTrigger.WorldLocation,
				PlayerOverlapTrigger.ComponentQuat,
				false))
			{
				OnPlayerOverlapTrigger(ClosestPlayer);
			}
		}
		
		bAnyPlayerCanSee = Mesh.WasRecentlyRendered(1.f);
		if(!bAnyPlayerCanSee)
		{	
			const float VisibilityDistance = 12000.f;
			const float ViewSize = 900.f;
			if(SceneView::ViewFrustumPointRadiusIntersection(LastPlayerThatCouldSee, CurrentSplineLocation, ViewSize, VisibilityDistance))
			{
				bAnyPlayerCanSee = true;
			}
			else if(SceneView::ViewFrustumPointRadiusIntersection(LastPlayerThatCouldSee.GetOtherPlayer(), CurrentSplineLocation, ViewSize, VisibilityDistance))
			{
				bAnyPlayerCanSee = true;
				LastPlayerThatCouldSee = LastPlayerThatCouldSee.GetOtherPlayer();
			}

			bHasResetAudioPos = false;
		}

		// 205 units for distance away from hatch
		// 200 units for distance to center of cart		
		const float OverlapHatchSizeSq = FMath::Square(205.f + 200.f);
		if(IsOverlappingHatchIndex < 0)
		{	
			for(int i = 0; i < OverlappableHatches.Num(); ++i)
			{
				const FHatchData HatchData = OverlappableHatches[i];
				if(HatchData.Hatch == nullptr)
					continue;
				
				if (CurrentSplineLocation.DistSquared(HatchData.Hatch.GetActorLocation()) > OverlapHatchSizeSq)
					continue;

				IsOverlappingHatchIndex = i;

				if(OverlappableHatches[IsOverlappingHatchIndex].bIsEnteringHatch)
				{
					EnterHatch();
				}
				else
					ExitHatch();

				OverlappableHatches[IsOverlappingHatchIndex].Hatch.AddOverlappingCart(this);
			}
		}
		else
		{
			const FHatchData HatchData = OverlappableHatches[IsOverlappingHatchIndex];
			if(HatchData.Hatch == nullptr
				|| CurrentSplineLocation.DistSquared(HatchData.Hatch.GetActorLocation()) > OverlapHatchSizeSq)
			{
				if(HatchData.Hatch != nullptr)
					OverlappableHatches[IsOverlappingHatchIndex].Hatch.RemoveOverlappingCart(this);

				IsOverlappingHatchIndex = -1;		
			}
		}

		if(bAnyPlayerCanSee)
		{	
			FRotator SplineRotation = RailCartMover.CurrentTransformOnSpline.Rotator();
			FRotator NewRotation = Math::MakeRotFromXZ(SplineRotation.ForwardVector, SplineRotation.UpVector);
			SetActorLocationAndRotation(RailCartMover.CurrentTransformOnSpline.Location, NewRotation);

			if(!bCouldSee || !bHasResetAudioPos)
			{
				if(HazeAkComponent.IsGameObjectRegisteredWithWwise())
				{
					// Reset the position when we can see the cart
					HazeAkComponent.SetRelativeLocationAndRotation(
						OriginalRelativeAudioTransform.Location, 
						OriginalRelativeAudioTransform.Rotation);

					bHasResetAudioPos = true;
				}
			}
		}
		else if(RailCartMover.CurrentMoveType == ETreeRailCartMoveType::Detached)
		{
			DestroyActor();
		}
	}

	void UpdateAudio(FTransform WorldTransform)
	{
		// We are already at the correct location
		if(bAnyPlayerCanSee)
			return;

		// It is possible that this object has been unregistered with wwise due to disable, and hasn't been enabled yet
		if(!HazeAkComponent.IsGameObjectRegisteredWithWwise())
			return;

		FTransform NewTransform = OriginalRelativeAudioTransform;
		NewTransform.Accumulate(WorldTransform);

		FVector WorldLocation = NewTransform.GetLocation();
		FRotator WorldRotation = NewTransform.Rotator();
		
		HazeAkComponent.SetWorldLocationAndRotation(WorldLocation, WorldRotation);
	}

	UFUNCTION()
	void SetActorLocationOnSpline(UHazeSplineComponent CurrentSpline)
	{
		if(!devEnsure(CurrentSpline != nullptr))
			return;

		const FTreeRailCartMovementDirection MoveDirData = GetMovementDirection(CurrentSpline);
		SetActorLocationAndRotation(MoveDirData.CartLocation, MoveDirData.CartRotation);
	}

	UFUNCTION()
	FTreeRailCartMovementDirection GetMovementDirection(UHazeSplineComponent CurrentSpline) const
	{
		FTreeRailCartMovementDirection Out;
		const float SplineDistance = CurrentSpline.GetDistanceAlongSplineAtWorldLocation(GetActorLocation());
		const FVector SplineDir = CurrentSpline.GetDirectionAtDistanceAlongSpline(SplineDistance, ESplineCoordinateSpace::World);
		Out.CartLocation = CurrentSpline.GetLocationAtDistanceAlongSpline(SplineDistance, ESplineCoordinateSpace::World);
		Out.bIsForwardOnSpline = SplineDir.DotProduct(GetActorForwardVector()) >= 0;
		if(Out.bIsForwardOnSpline)
			Out.CartRotation = SplineDir.Rotation();
		else
			Out.CartRotation = (-SplineDir).Rotation();
		return Out;
	}

	UFUNCTION()
	void ActivateRailMovement(UHazeSplineComponent CurrentSpline, ATreeRailCart ParentCart, float StartSpeed, bool bWrapAtEnd, bool bUseForces)
	{
		if(StartSpeed <= KINDA_SMALL_NUMBER)
			return;

		if(!devEnsure(CurrentSpline != nullptr))
			return;

		RailCartMover.bApplyForces = bUseForces;
		RailCartMover.CurrentSpeed = FMath::Max(RailCartMover.CurrentSpeed, StartSpeed);

		const FTreeRailCartMovementDirection MoveDirData = GetMovementDirection(CurrentSpline);
		SetActorLocationAndRotation(MoveDirData.CartLocation, MoveDirData.CartRotation);
		RailCartMover.CurrentTransformOnSpline = GetActorTransform();
		SplineFollow.ActivateSplineMovement(CurrentSpline, MoveDirData.bIsForwardOnSpline);

		if(ParentCart == nullptr)
		{
			RailCartMover.ActivateMovement(bWrapAtEnd ? ETreeRailCartMoveType::ActiveWrapAtEnd : ETreeRailCartMoveType::Active);
		}
		else
		{
			// The parent must tick first
			RailCartMover.ActivateMovement(ETreeRailCartMoveType::FollowParent);
			
			const FHazeSplineSystemPosition CurrentSplinePosition = SplineFollow.GetPosition();
			const float SplineLength = CurrentSplinePosition.Spline.SplineLength;
			
			const FHazeSplineSystemPosition ParentSplinePosition = ParentCart.SplineFollow.GetPosition();
			const float ParentSplineLength = ParentSplinePosition.Spline.SplineLength;

			ParentCart.FollowingCarts.AddUnique(this);
			RailCartMover.ParentMover = ParentCart.RailCartMover;

			// If we are going to keep up with the parent, we need to move with a multiplier of the parents spline
			RailCartMover.DistanceToKeepToParent = ParentSplinePosition.DistanceAlongSpline - CurrentSplinePosition.DistanceAlongSpline;
			RailCartMover.MovementMultiplier = ParentSplineLength / SplineLength;
			RailCartMover.AddTickPrerequisiteComponent(ParentCart.RailCartMover);		
		}
	}

	UFUNCTION()
	void DeactivateMovement()
	{
		RailCartMover.DeactivateMovement();
	}

	UFUNCTION(BlueprintEvent)
	void OnPlayerOverlapTrigger(AHazePlayerCharacter CollidingPlayer) 
	{

	}

	UFUNCTION(BlueprintEvent)
	void EnterHatch() 
	{
	}

	UFUNCTION(BlueprintEvent)
	void ExitHatch() 
	{
	}
}

struct FTreeRailCartMovementDirection
{
	UPROPERTY()
	bool bIsForwardOnSpline = true;

	UPROPERTY()
	FVector CartLocation = FVector::ZeroVector;

	UPROPERTY()
	FRotator CartRotation = FRotator::ZeroRotator;
}

struct FHatchCollectStatus
{
	UPROPERTY()
	bool bIsEnteringHatch = false;

	UPROPERTY()
	bool bIsValidHatch = false;
}

struct FHatchData
{
	UPROPERTY()
	ATreeRailCartHatch Hatch = nullptr;

	UPROPERTY()
	bool bIsEnteringHatch = false;
}
