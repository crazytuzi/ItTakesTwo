import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Capabilities.LedgeVault.LedgeVaultSettings;
import Peanuts.Movement.GroundTraceFunctions;
import Vino.Movement.Capabilities.LedgeVault.Capabilities.LedgeVaultNames;
import Vino.Movement.MovementSystemTags;

struct FLedgeVaultData
{
	UPrimitiveComponent FrontLedge = nullptr;
	UPrimitiveComponent TopLedge = nullptr;

	// In worldspace on non networked objects otherwise it is local to the object.
	FVector StartLocation = FVector::ZeroVector;
	FVector TopOfLedgeLocation = FVector::ZeroVector;
	FVector FullDeltaToTravel = FVector::ZeroVector;

	void SetLocation(UPrimitiveComponent inFrontLedge, UPrimitiveComponent inTopLedge, FVector inStartLocation, FVector inTopOfLedgeLocation)
	{
		// We keep the characters location in relative so if the object moves then we can keep the location data relative to the object.
		// If the object is not networked then the object is not allowed to move and we keep the location data in worldspace.

		FullDeltaToTravel = inTopOfLedgeLocation - inStartLocation;
		if (inTopLedge != nullptr && inTopLedge.IsNetworked())
		{
			FrontLedge = inFrontLedge;
			TopLedge = inTopLedge;
			FTransform LedgeTransform = inTopLedge.WorldTransform;
			StartLocation = LedgeTransform.InverseTransformPosition(inStartLocation);
			TopOfLedgeLocation = LedgeTransform.InverseTransformPosition(inTopOfLedgeLocation);
		}
		else
		{
			StartLocation = inStartLocation;
			TopOfLedgeLocation = inTopOfLedgeLocation;
		}
	}

	FVector GetTopOfLedge() const property
	{
		if (TopLedge != nullptr)
		{
			FTransform LedgeTransform = TopLedge.WorldTransform;
			return LedgeTransform.TransformPosition(TopOfLedgeLocation);
		}
		else
		{
			return TopOfLedgeLocation;
		}
	}

	FVector GetVaultingStartLocation() const property
	{
		if (TopLedge != nullptr)
		{
			FTransform LedgeTransform = TopLedge.WorldTransform;
			return LedgeTransform.TransformPosition(StartLocation);
		}
		else
		{
			return StartLocation;
		}
	}
}

/*
	Goal of the capability is cover the cases where the player impacts a surface that is almost a ledgegrab where the players instead get stuck and loses momemtum.
*/
class UCharacterLedgeVaultCapability : UCharacterMovementCapability
{
	default RespondToEvent(MovementActivationEvents::Airbourne);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::LedgeVault);

	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 20;

	float ActiveTimer = 0.f;

	bool bActivateVaulting = false;

	FVector DeltaTraveled = FVector::ZeroVector;
	FLedgeVaultData LedgeData;

	FLedgeVaultSettings Settings;
	FVector LastMovedDelta = FVector::ZeroVector;

	AHazePlayerCharacter PlayerOwner;

	ULedgeVaultDynamicSettings DynamicSettings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		ensure(PlayerOwner != nullptr);
		DynamicSettings = ULedgeVaultDynamicSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
#if EDITOR
		if (!IsActioning(MovementActivationEvents::Airbourne))
			return EHazeNetworkActivation::DontActivate;
#endif

		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;
		
		if (bActivateVaulting)
			return EHazeNetworkActivation::ActivateUsingCrumb;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (ActiveTimer >= DynamicSettings.LerpTime)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
	
	UFUNCTION(BlueprintOverride)
	void PreTick_EventBased()
	{
		if (IsActive())
			return;

		if (IsBlocked())
			return;

		bActivateVaulting = ShouldVault(LedgeData, IsDebugActive());
	}


	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)const
	{
		Params.AddObject(LedgeVaultSyncTags::Ledge, LedgeData.TopLedge);
		Params.AddVector(LedgeVaultSyncTags::StartLocation, LedgeData.StartLocation);
		Params.AddVector(LedgeVaultSyncTags::TargetLocation, LedgeData.TopOfLedgeLocation);
	}

	void RemoteLoadActivationVariables(FCapabilityActivationParams ActivationParams)
	{
		// On the remote we don't care about our front hit because we ignore all wall hits anyway.
		LedgeData.SetLocation(nullptr, Cast<UPrimitiveComponent>(ActivationParams.GetObject(LedgeVaultSyncTags::Ledge)),
		 	ActivationParams.GetVector(LedgeVaultSyncTags::StartLocation),
		  	ActivationParams.GetVector(LedgeVaultSyncTags::TargetLocation));	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(ActionNames::WeaponAim, this);

		bActivateVaulting = false;
		DeltaTraveled = FVector::ZeroVector;
		ActiveTimer = 0.f;

		if (HasControl())
		{
			MoveComp.StartIgnoringComponent(LedgeData.FrontLedge);
			MoveComp.StartIgnoringComponent(LedgeData.TopLedge);
		}
		else
		{
			RemoteLoadActivationVariables(ActivationParams);
		}

		PlayerOwner.ApplyPivotLagMax(FVector(200.f, 200.f, 400.f), this, EHazeCameraPriority::Medium);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(ActionNames::WeaponAim, this);

		if (LedgeData.FrontLedge != nullptr)
			MoveComp.StopIgnoringComponent(LedgeData.FrontLedge);

		if (LedgeData.TopLedge != nullptr)
			MoveComp.StopIgnoringComponent(LedgeData.TopLedge);

		MoveComp.SetVelocity(MoveComp.OwnerRotation.ForwardVector * MoveComp.MoveSpeed);
		LedgeData = FLedgeVaultData();

		PlayerOwner.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ActiveTimer += DeltaTime;

		FVector NewOffset = FMath::Lerp(FVector::ZeroVector, LedgeData.FullDeltaToTravel, ActiveTimer / DynamicSettings.LerpTime);
		FVector FrameDelta = NewOffset - DeltaTraveled;
		DeltaTraveled = DeltaTraveled + FrameDelta;

        FHazeFrameMovement VaultMove = MoveComp.MakeFrameMovement(n"CharacterLedgeVault");
		VaultMove.OverrideStepUpHeight(0);
		VaultMove.OverrideStepDownHeight(0);
			
		VaultMove.ApplyDelta(FrameDelta);
		VaultMove.OverrideGroundedState(EHazeGroundedState::Grounded);

		float DistanceToEndPoint = (LedgeData.TopOfLedge - MoveComp.OwnerLocation).Size();
		PlayerOwner.SetAnimFloatParam(LedgeVaultAnimParams::DistanceToTop, DistanceToEndPoint);

		if (LedgeData.TopLedge != nullptr)
			VaultMove.SetMoveWithComponent(LedgeData.TopLedge);
		
        MoveCharacter(VaultMove, n"CharacterLedgeVault");
	}

	bool ShouldVault(FLedgeVaultData& OutVaultData, const bool bDebugDraw) const
	{
		// Activate when we impacts with a surface and we are close enough to the top/ledge of the object to quickly climb up it.
		if (!MoveComp.IsAirborne())
		 	return false;

		float VerticalSpeed = MoveComp.RequestVelocity.DotProduct(MoveComp.WorldUp);

		// Allow vaulting if you are falling, but only if you are going slow enough
		if (VerticalSpeed < -MoveComp.MaxFallSpeed * 0.5f)
			return false;

		// Allow vaulting if you are moving upwards, but only if you are going slow enough
		if (VerticalSpeed > MoveComp.MaxFallSpeed * 0.45f)
			return false;

		// You should not vault if you arent requesting to move forwards fast enough
		FVector HorizontalVelocity = MoveComp.RequestVelocity.ConstrainToPlane(MoveComp.WorldUp);
		float HorizontalSpeed = HorizontalVelocity.Size();
		if (HorizontalSpeed <= MoveComp.MoveSpeed * 0.05f)
			return false;

		const FVector ForwardAnticapation = MoveComp.Velocity * Settings.TimeAnticipation;

		FHazeHitResult HitToCheck;
		HitToCheck.OverrideFHitResult(MoveComp.ForwardHit);

		if (!HitToCheck.bBlockingHit)
		{
			if (PredictVaultHit(HitToCheck))
				return false;

			if (IsHitSurfaceWalkableDefault(HitToCheck.FHitResult, MoveComp.ActiveSettings.WalkableSlopeAngle, MoveComp.WorldUp))
				return false;
		}

		// Player has too give input towards the wall to activate the vault.
		FVector InputVector = GetAttributeVector(AttributeVectorNames::MovementDirection);
		FVector ToWall = -HitToCheck.Normal;
		float InputWallDot = InputVector.DotProduct(ToWall);

		if (InputWallDot < Settings.InputActivationTreshold)
			return false;

		// Examine the hit to se if we hit close enough to a ledge.
		FHitResult TopHit;
		if (!IsHitLedgeHit(HitToCheck.FHitResult, TopHit, bDebugDraw))
			return false;

		// Offset the character start position from the ledge top position.
		OutVaultData.SetLocation(HitToCheck.Component, TopHit.Component, MoveComp.OwnerLocation, TopHit.ImpactPoint + MoveComp.WorldUp * 3.f);
		if (bDebugDraw)
		{
			System::DrawDebugLine(MoveComp.OwnerLocation, MoveComp.OwnerLocation + OutVaultData.FullDeltaToTravel, FLinearColor::Green);
			System::DrawDebugSphere(MoveComp.OwnerLocation + OutVaultData.FullDeltaToTravel, 10.f, 12, FLinearColor::Green, 5.f);
		}

		return true;
	}

	bool PredictVaultHit(FHazeHitResult& OutHit) const
	{
		FHazeTraceParams ForwardTrace;
		ForwardTrace.InitWithMovementComponent(MoveComp);
		ForwardTrace.UnmarkToTraceWithOriginOffset();

		float UpOffset = DynamicSettings.PredictionTraceOffset;
		if (MoveComp.Velocity.DotProduct(MoveComp.WorldUp) < 0.f)
			UpOffset = 0.f;
		
		FVector Bounds = MoveComp.GetActorShapeExtents();
		float TraceHeight = ((Bounds.Z * 2.f) - UpOffset) / 2.f;
		ForwardTrace.SetToCapsule(Bounds.X, TraceHeight);

		float Offset = (Bounds.Z * 2.f) - TraceHeight; 
		FVector FromLocation = MoveComp.OwnerLocation + MoveComp.WorldUp * Offset;

		const FVector ForwardAnticapation = MoveComp.Velocity * Settings.TimeAnticipation;
		ForwardTrace.From = FromLocation;
		ForwardTrace.To = FromLocation + ForwardAnticapation;
		ForwardTrace.DebugDrawTime = IsDebugActive() ? 0.f : -1.f;

		return ForwardTrace.Trace(OutHit);
	}

	bool IsHitLedgeHit(FHitResult Hit, FHitResult& OutHit, const bool bDebugDraw) const
	{
		// Do straight trace down to find the top.
		FVector From = Hit.ImpactPoint + -Hit.Normal * DynamicSettings.FindTopDepth + MoveComp.WorldUp * DynamicSettings.FindTopHeight;
		FVector Delta = -MoveComp.WorldUp * (DynamicSettings.FindTopHeight + 5.f); // Add extra to make sure we hit a surface on the way down.

		if (!LineTrace(From, Delta, OutHit, bDebugDraw))
		{
			return false; // Something has probably gone wrong if we don't hit anything here.
		}

		if (!OutHit.Component.HasTag(ComponentTags::LedgeVaultable))
			return false;

		if (!IsHitSurfaceWalkableDefault(OutHit, MoveComp.ActiveSettings.WalkableSlopeAngle, MoveComp.WorldUp))
			return false;

		FVector CharacterToTop = MoveComp.OwnerLocation - OutHit.ImpactPoint;
		if (CharacterToTop.SizeSquared() > FMath::Square(DynamicSettings.MaxiumDistanceToTop))
		{
			if (bDebugDraw)
				System::DrawDebugArrow(MoveComp.OwnerLocation, OutHit.ImpactPoint, 5.f, FLinearColor::Red);

			return false;
		}

		// Check that the player will fit up there and can get their.
		FVector CheckExtents;
		CheckExtents.X = (MoveComp.ActorShapeExtents.X * 1.75f) + DynamicSettings.FindTopDepth;
		CheckExtents.Y = MoveComp.ActorShapeExtents.X * 1.75f;
		CheckExtents.Z = MoveComp.ActorShapeExtents.Z;

		FVector OffsetedTopLocation = OutHit.ImpactPoint + MoveComp.WorldUp * 0.05f;
		FVector OverlapLocation = OffsetedTopLocation;// - (Hit.Normal * DynamicSettings.FindTopDepth);
		FHazeTraceParams AreaCheck;
		AreaCheck.InitWithMovementComponent(MoveComp);
		AreaCheck.SetToBox(CheckExtents);
		AreaCheck.OverlapLocation = OverlapLocation;
		AreaCheck.DebugDrawTime = IsDebugActive() ? 2.f : -1.f;

		if (AreaCheck.Overlap(TArray<FOverlapResult>()))
		{
			if (bDebugDraw)
				System::DrawDebugCapsule(OffsetedTopLocation, MoveComp.ActorShapeExtents.Z, MoveComp.ActorShapeExtents.X, MoveComp.OwnerRotation.Rotator(), FLinearColor::Red);

			return false;
		}

		if (bDebugDraw)
			System::DrawDebugCapsule(OffsetedTopLocation, MoveComp.ActorShapeExtents.Z, MoveComp.ActorShapeExtents.X, MoveComp.OwnerRotation.Rotator(), FLinearColor::Green);

		return true;
	}

	bool LineTrace(FVector From, FVector Delta, FHitResult& Hit, const bool bDebugDraw) const
	{
		const FVector To = From + Delta;

		FHazeHitResult HitResult;
		if (MoveComp.LineTrace(From, To, HitResult) && !HitResult.bStartPenetrating)
		{
			if (bDebugDraw)
				System::DrawDebugArrow(From, HitResult.ImpactPoint, 5.f, FLinearColor::Green, 2.f);

			Hit = HitResult.FHitResult;

			return true;
		}

		if (bDebugDraw)
			System::DrawDebugArrow(From, To, 5.f, FLinearColor::Red, 2.f);

		Hit = HitResult.FHitResult;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString DebugText = "";
		return DebugText;
	}

};
