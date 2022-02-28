import Cake.Weapons.Match.MatchWielderComponent;
import Cake.Weapons.Match.MatchWeaponActor;
import Cake.Weapons.Match.MatchWeaponSocketDefinition;
import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Capabilities.CameraTags;
import Cake.Weapons.Match.MatchCrosshairWidget;
import Peanuts.Aiming.AutoAimStatics;
import Cake.Weapons.Match.MatchAntiAutoAimTargetComponent;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Grinding.GrindingCapabilityTags;

UCLASS(abstract)
class UMatchWeaponAimCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(ActionNames::WeaponAim);
	default CapabilityTags.Add(n"MatchWeaponMovement");
	default CapabilityTags.Add(n"MatchWeaponAim");
	default CapabilityTags.Add(n"MatchWeapon");
	default CapabilityTags.Add(n"Weapon");

	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::LastDemotable;
	default TickGroupOrder = 100;

	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = "Movement")
	float RotateWielderTowardsAimDirectionSpeed = 20.f;

	// Camera settings used while aiming
	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset CameraSettings_Aiming = nullptr;

	// blend in time for pushing camera Settings while Aiming 
	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = "Camera")
	float CameraSettingsBlendInTime = 0.5f;

	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = "MISC")
	TSubclassOf<UMatchCrosshairWidget> CrossHairWidget;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionStateMachineAsset LocoAsset_NotAiming;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionStateMachineAsset LocoAsset_Aiming;

	UPROPERTY(Category = "MISC")
	float ShootTraceLength = 10000.f;

	UPROPERTY(Category = "MISC")
	float AutoAimMinDistance = 100.f;

	// Settings 
	//////////////////////////////////////////////////////////////////////////
	// Transient 

	float PrevCamYAW = 0.f;
	UMatchCrosshairWidget CrossHairWidgetInstance = nullptr;
	UHazeActiveCameraUserComponent CameraUser = nullptr;
	UMatchWielderComponent WielderComp = nullptr;
	AHazePlayerCharacter Player = nullptr;
	UHazeMovementComponent MoveComp = nullptr;
	AMatchWeaponActor Crossbow = nullptr;
	FVector CurrentAimWorldLocation = FVector::ZeroVector;
	FAutoAimState AutoAim(OcclusionCacheFrames = 10);
	UUserGrindComponent GrindComp;

	// Transient 
	//////////////////////////////////////////////////////////////////////////
	// Capability Functions

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CameraUser = UHazeActiveCameraUserComponent::Get(Owner);
		WielderComp = UMatchWielderComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		Crossbow = WielderComp.GetMatchWeapon();
		GrindComp = UUserGrindComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IsActioning(ActionNames::WeaponAim))
			return EHazeNetworkActivation::DontActivate;

		if(!WielderComp.HasMatchWeapon())
			return EHazeNetworkActivation::DontActivate;

	    if (GrindComp.HasTargetGrindSpline())
	        return EHazeNetworkActivation::DontActivate;

		if(Player.IsAnyCapabilityActive(n"DashSlowdown"))
	        return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(ActionNames::WeaponAim))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!WielderComp.HasMatchWeapon())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

	    if (GrindComp.HasTargetGrindSpline())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(Player.IsAnyCapabilityActive(n"DashSlowdown"))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.SetCapabilityActionState(n"Aiming", EHazeActionState::Active);

		Owner.BlockCapabilities(n"MatchWeaponIdle", this);
		Owner.BlockCapabilities(n"CharacterFacing", this);
		Owner.BlockCapabilities(MovementSystemTags::TurnAround, this);
		Owner.BlockCapabilities(MovementSystemTags::Sprint, this);
//		Owner.BlockCapabilities(CameraTags::PointOfInterest, this);
		Owner.BlockCapabilities(CameraTags::ChaseAssistance, this);
		Owner.BlockCapabilities(GrindingCapabilityTags::Camera, this);
		
		AddAimWidget();
		ApplyAimCameraSettings();

		WielderComp.bAiming = true;
		PrevCamYAW = Player.GetPlayerViewRotation().Yaw;
		WielderComp.ShuffleRotation = 0.f;

		Player.AddLocomotionAsset(LocoAsset_Aiming, this);

		Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_Weapons_Guns_Rifle_Match_IsAiming", 1.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveAimWidget();
		ClearAimCameraSettings();

		ConsumeAction(n"Aiming");

		WielderComp.bAiming = false;

		Owner.UnblockCapabilities(n"MatchWeaponIdle", this);
		Owner.UnblockCapabilities(n"CharacterFacing", this);
//		Owner.UnblockCapabilities(CameraTags::PointOfInterest, this);
		Owner.UnblockCapabilities(MovementSystemTags::TurnAround, this);
		Owner.UnblockCapabilities(MovementSystemTags::Sprint, this);
		Owner.UnblockCapabilities(CameraTags::ChaseAssistance, this);
		Owner.UnblockCapabilities(GrindingCapabilityTags::Camera, this);

		Player.ClearLocomotionAssetByInstigator(this);

		Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_Weapons_Guns_Rifle_Match_IsAiming", 0.f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Crossbow.GetLoadedMatch() == nullptr)
		{
			ensure(false);
			return;
		}

		GatherTargetData_Aim(WielderComp.TargetData);

		// Rotate up the camera towards camera looking direction
		MoveComp.SetTargetFacingDirection(
			Player.GetViewRotation().Vector(),
			RotateWielderTowardsAimDirectionSpeed
		);

		UpdateAnimationParams(DeltaTime);

		UpdateWidget();
	}

	void UpdateAnimationParams(const float Dt)
	{
		// YAW 
		const FVector PlayerForward = Player.GetActorForwardVector();
		const FRotator CameraRotator = Player.GetPlayerViewRotation();
		const FVector CameraForward = CameraRotator.Vector();
		const FVector CameraForward_ConstrainedToXY = CameraForward.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
		const FVector CrossUp = PlayerForward.CrossProduct(CameraForward_ConstrainedToXY);
		const float AbsoluteYaw_RAD = FMath::Acos(PlayerForward.DotProduct(CameraForward_ConstrainedToXY));
		const float Yaw_RAD = AbsoluteYaw_RAD * FMath::Sign(CrossUp.DotProduct(FVector::UpVector));
		const float Yaw_DEG = FMath::RadiansToDegrees(Yaw_RAD);

		// PITCH
		const float Pitch_DEG = CameraRotator.Pitch;

		WielderComp.AimAngles = FVector2D(Yaw_DEG, Pitch_DEG);

		// range = [0, 360] degrees
		//WielderComp.ShuffleRotation = CameraRotator.Yaw;
		//WielderComp.ShuffleRotation += 180.f;

		if(MoveComp.BecameGrounded())
			WielderComp.ShuffleRotation = 0.f;

		WielderComp.ShuffleRotation += FRotator::NormalizeAxis(CameraRotator.Yaw - PrevCamYAW);
		WielderComp.ShuffleRotation = FRotator::ClampAxis(WielderComp.ShuffleRotation);

		float AimRotationSpeed = 0.f;
		if(Dt != 0.f)
		{
			AimRotationSpeed = CameraRotator.Yaw - PrevCamYAW;
			AimRotationSpeed /= Dt;
			AimRotationSpeed = FMath::UnwindDegrees(AimRotationSpeed);
		}
		PrevCamYAW = CameraRotator.Yaw;
		Player.SetAnimFloatParam(n"AimRotationSpeed", AimRotationSpeed);

		// Update the look at Rotation
		const FVector WeaponTraceStart = Crossbow.Mesh.GetSocketLocation(
			GetMatchWeaponSocketNameFromDefinition(EMatchWeaponSocketDefinition::StartWeaponTraceSocket)
		);

		// Update LookAt 
		const FVector DesiredTargetLocation = WielderComp.TargetData.GetTargetLocation();
		FQuat DesiredQuat = Math::MakeQuatFromX(DesiredTargetLocation - WeaponTraceStart);

		// WorldSpace to Component Space
		DesiredQuat = Player.GetActorQuat().Inverse() * DesiredQuat;
		// DesiredQuat = Player.GetActorTransform().InverseTransformRotation(DesiredQuat.Rotator()).Quaternion();

		// WielderComp.LookAtRot.AccelerateTo(DesiredQuat.Rotator(), 0.6f, Dt);
		WielderComp.LookAtRot.SpringTo(DesiredQuat.Rotator(), 200.f, 0.6f, Dt);
		// WielderComp.LookAtRot.SnapTo(DesiredQuat.Rotator());
	}

	void AddAimWidget()
	{
		if (!CrossHairWidget.IsValid())
			return;

		CrossHairWidgetInstance = Cast<UMatchCrosshairWidget>(Player.AddWidget(CrossHairWidget));

		if(Crossbow.GetLoadedMatch() == nullptr)
			return;

		GatherTargetData_Aim(WielderComp.TargetData);

		const FVector TargetAimLocation = WielderComp.TargetData.GetTargetLocation();
		CrossHairWidgetInstance.AimWorldLocationDesired = TargetAimLocation;
		CrossHairWidgetInstance.AimWorldLocationCurrent = TargetAimLocation;
		CrossHairWidgetInstance.bIsAutoAimed = WielderComp.TargetData.IsAutoAiming();
	}

	void UpdateWidget()
	{
		CrossHairWidgetInstance.AimWorldLocationDesired = WielderComp.TargetData.GetTargetLocation();
		// CrossHairWidgetInstance.AimWorldLocationDesired.X = FMath::RoundToFloat(CrossHairWidgetInstance.AimWorldLocationDesired.X);
		// CrossHairWidgetInstance.AimWorldLocationDesired.Y = FMath::RoundToFloat(CrossHairWidgetInstance.AimWorldLocationDesired.Y);
		// CrossHairWidgetInstance.AimWorldLocationDesired.Z = FMath::RoundToFloat(CrossHairWidgetInstance.AimWorldLocationDesired.Z);

		CrossHairWidgetInstance.bIsAutoAimed = WielderComp.TargetData.IsAutoAiming();
		// PrintToScreen("" + CrossHairWidgetInstance.AimWorldLocationDesired);
		// System::DrawDebugPoint(CrossHairWidgetInstance.AimWorldLocationDesired, 10.f);
	}

	void RemoveAimWidget()
	{
		if (!CrossHairWidget.IsValid())
			return;

		Player.RemoveWidget(CrossHairWidgetInstance);
	}

	void ApplyAimCameraSettings()
	{
		// auto BlendSettings = FHazeCameraBlendSettings();
		// BlendSettings.BlendTime = CameraSettingsBlendInTime;

		Player.ApplyCameraSettings
		(
			CameraSettings_Aiming,
			// FHazeCameraBlendSettings(1.f),
			FHazeCameraBlendSettings(CameraSettingsBlendInTime),
			// BlendSettings,
			this,
			EHazeCameraPriority::High
		);
		CameraUser.SetAiming(this);
	}

	void ClearAimCameraSettings()
	{
		Player.ClearCameraSettingsByInstigator(this);
		CameraUser.ClearAiming(this);
	}

	bool WielderWantsToStandStill() const
	{
		const FVector MovementDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
		return MovementDirection.IsNearlyZero();
	}

	void GatherTargetData_Aim(FMatchTargetData& TargetData)
	{
		// reset data
		TargetData = FMatchTargetData();

		const FVector WeaponTraceStart = Crossbow.Mesh.GetSocketLocation(
			GetMatchWeaponSocketNameFromDefinition(EMatchWeaponSocketDefinition::StartWeaponTraceSocket)
		);

		FVector AimOrigin = Player.GetViewLocation();
		FVector AimDirection = Player.GetViewRotation().Vector();

		const FVector CameraTraceStart = FMath::ClosestPointOnInfiniteLine(
			AimOrigin,
			AimOrigin + (AimDirection * ShootTraceLength),
			WeaponTraceStart
		);

		// Project the camera location fowards to where the weapon is and start the trace from there
		AimOrigin = CameraTraceStart;

		// cosmetic fix for when shooting the match just before the camera has fully blended in. 
		Crossbow.GetLoadedMatch().bAimCameraFullyBlendedIn = GetActiveDuration() > CameraSettingsBlendInTime;

		// @TODO: do we even use full screen anymore? Beetle, but that guy has it's own aim capability?
		if (WielderComp.ShouldFullscreenAim())
		{
			AHazePlayerCharacter ScreenPlayer = SceneView::IsFullScreen() ? SceneView::GetFullScreenPlayer() : Player;
			SceneView::DeprojectScreenToWorld_Relative(ScreenPlayer, WielderComp.AimPositionPercent, AimOrigin, AimDirection);
		}

		/* Correct using auto-aim on our line trace. */
		FAutoAimLine Aim = GetAutoAimForTargetLine(
			Player,
			AimOrigin,
			AimDirection,
			AutoAimMinDistance,
			ShootTraceLength,
			bCheckVisibility = true 
		);

		// Handle valid AutoAim
		if(Aim.bWasAimChanged 
		&& Aim.AutoAimedAtComponent != nullptr
		&& Cast<UMatchAntiAutoAimTargetComponent>(Aim.AutoAimedAtComponent) == nullptr)
		{
			TargetData.bHoming = true;
			TargetData.bAutoAim = true;

			TargetData.TraceStart = Aim.AimLineStart;
			TargetData.TraceEnd = Aim.AimLineStart + Aim.AimLineDirection * ShootTraceLength;

			TargetData.SetTargetLocation(
				// Aim.AutoAimedAtPoint,
				Aim.AutoAimedAtComponent.GetWorldLocation(),
				Aim.AutoAimedAtComponent,
				NAME_None
			);

			return;
		}

		const FVector CameraTraceEnd = AimOrigin + (AimDirection * ShootTraceLength);

		// Auto aim failed. Lets do our own trace.
		FHitResult CameraHit;
		TargetData.TraceStart = CameraTraceStart;
		TargetData.TraceEnd = CameraTraceEnd;

		// We are making an assumption here that if you trace from within an object 
		// that the Hitresult will get discarded. @TODO: proper fix is to do a 
		// Trace that keeps on tracing even if it gets a blockingHit. 
		// This is doable in c++, but expensive
		if(RayTrace( CameraTraceStart, CameraTraceEnd, CameraHit))	
		{
			TargetData.bHoming = true;

			TargetData.SetTargetLocation(
				CameraHit.ImpactPoint,
				CameraHit.Component,
				CameraHit.BoneName
			);
		}

	}

	bool RayTrace(FVector Start, FVector End, FHitResult& OutHit)
	{
		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Reserve(WielderComp.Matches.Num() + 2);
		for(AActor IterMatch : WielderComp.Matches)
			ActorsToIgnore.Add(IterMatch);
		ActorsToIgnore.Add(Player);
		ActorsToIgnore.Add(WielderComp.GetMatchWeapon());

		bool bHit = System::LineTraceSingle(
			Start,
			End,
			ETraceTypeQuery::WeaponTrace,
			false, // TraceComplex
			ActorsToIgnore,
			EDrawDebugTrace::None,
			OutHit,
			true
		);

		return bHit;

		//////////////////////////////////////////////////////////////////////////////////////
		// for future reference: The multi trace was used in order to hit the swarm.
		//////////////////////////////////////////////////////////////////////////////////////

		// TArray<FHitResult> MultiHits;
		// System::LineTraceMulti
		// (
		// 	Start,
		// 	End,
		// 	ETraceTypeQuery::WeaponTrace,
		// 	false, // TraceComplex
		// 	ActorsToIgnore,
		// 	EDrawDebugTrace::ForOneFrame,
		// 	MultiHits,
		// 	false
		// );

		// if(MultiHits.Num() != 0)
		// 	OutHit = MultiHits[0];

		// return MultiHits.Num() != 0;
	}

}






















