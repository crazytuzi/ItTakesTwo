import Cake.LevelSpecific.Tree.BeetleRiding.TreeBeetleRidingComponent;
import Cake.Weapons.Match.MatchWielderComponent;
import Cake.Weapons.Match.MatchWeaponSocketDefinition;
import Peanuts.Aiming.AutoAimStatics;
import Cake.Weapons.Match.MatchCrosshairWidget;
import Cake.LevelSpecific.Tree.BeetleRiding.TreeBeetleRidingEnemy;

class UTreeBeetleRidingAimCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"BeetleRiding";

	default CapabilityTags.Add(n"BeetleRiding");

	bool bDrawWidget = true;
	bool bDrawAimArrow = false;
	bool bDrawDebug = false;

	FHazeAcceleratedVector AccCurrentAimWorldLocation;

	bool bHasTarget;
	bool bPrevHasTarget;

	UTreeBeetleRidingComponent BeetleRidingComponent;
	AHazePlayerCharacter Player;
	UMatchWielderComponent Wielder;
	UAutoAimComponent AutoAimComponent;

	float GainAutoAimSnapTime = 0.f;
	float LoseAutoAimSnapTime = 0.f;

	FRotator AimRotation;
	FVector CurrentAimWorldLocation;

	UMatchCrosshairWidget CrossHairWidgetInstance = nullptr;

	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = "MISC")
	TSubclassOf<UMatchCrosshairWidget> CrossHairWidget;

	UHazeSmoothSyncVectorComponent NetSyncAimLocationComp;
 
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		BeetleRidingComponent = UTreeBeetleRidingComponent::Get(Player);
		Wielder = UMatchWielderComponent::Get(Player);
		AutoAimComponent = UAutoAimComponent::GetOrCreate(Player);

		NetSyncAimLocationComp = UHazeSmoothSyncVectorComponent::GetOrCreate(Player, n"BeetleMatchAimLocation");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(BeetleRidingComponent.Beetle == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!BeetleRidingComponent.Beetle.bIsRunning)
			return EHazeNetworkActivation::DontActivate;

		if(Wielder == nullptr)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(BeetleRidingComponent.Beetle == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!BeetleRidingComponent.Beetle.bIsRunning)
			return EHazeNetworkDeactivation::DeactivateLocal;	

		if(Wielder == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AddAimWidget();
		Wielder.bAiming = true;
		Player.BlockCapabilities(ActionNames::WeaponAim, this);
		NetSyncAimLocationComp = UHazeSmoothSyncVectorComponent::GetOrCreate(Player, n"BeetleMatchAimLocation");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveAimWidget();

		Wielder.bAiming = false;

		Player.UnblockCapabilities(ActionNames::WeaponAim, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FTransform LocalToWorld = Owner.GetActorTransform();

		if (HasControl())
		{
			GatherTargetData(DeltaTime);


			// Net sync values for widget
			// NetSyncAimLocationComp.Value = LocalToWorld.InverseTransformPosition(CurrentAimWorldLocation);
			NetSyncAimLocationComp.Value = CurrentAimWorldLocation - LocalToWorld.GetLocation();

			if (bHasTarget != bPrevHasTarget)
			{
				// @TODO: we should sync the auto aim targetcomponent as well,
				// so that we can snap to it faster, cause we know were we are going.
				bPrevHasTarget = bHasTarget;
				NetSetHasTarget(bHasTarget);
			}
		}

		// update widget

		CrossHairWidgetInstance.AimWorldLocationDesired = NetSyncAimLocationComp.Value + LocalToWorld.GetLocation();
		// CrossHairWidgetInstance.AimWorldLocationDesired = LocalToWorld.TransformPosition(NetSyncAimLocationComp.Value);

		// System::DrawDebugSphere(CrossHairWidgetInstance.AimWorldLocationDesired, Duration = 2.f);

		CrossHairWidgetInstance.bIsAutoAimed = bHasTarget;
	}

	UFUNCTION(NetFunction)
	void NetSetHasTarget(bool bAutoAim)
	{
		bHasTarget = bAutoAim;
	}

	const float AimTraceLength = 10000.f;

	// This Controls the Clamps and Where May is aiming.
	const float AimWidgetFrustrumClamp = 1000.f;

	FVector2D PrevMouseInput = FVector2D::ZeroVector;

	void GatherTargetData(const float DeltaTime) 
	{
		// Get Input
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);

		float AimRotationLerpSpeed = 2.5f;
		if(!Player.IsUsingGamepad())
		{
			FVector2D NewMouseInput = PrevMouseInput;

			FVector2D AddedMouseDelta = Input;
			AddedMouseDelta *= 0.1f;
			NewMouseInput += AddedMouseDelta;

			NewMouseInput.X = FMath::Clamp(NewMouseInput.X, -1.f, 1.f);
			NewMouseInput.Y = FMath::Clamp(NewMouseInput.Y, -1.f, 1.f);

			Input = NewMouseInput;

			// No lerping when using mouse
			AimRotationLerpSpeed = 0.f;
		}

		// needs to be here in case we switch between gamepad and mouse
		PrevMouseInput = Input;

		Input.X = FMath::GetMappedRangeValueClamped(FVector2D(-0.7, 0.7),FVector2D(-1.f, 1.f), Input.X);
		Input.Y = FMath::GetMappedRangeValueClamped(FVector2D(-0.7, 0.7),FVector2D(-1.f, 1.f), Input.Y);

		AimRotation = FMath::RInterpTo(AimRotation, FRotator(Input.Y * 40.f, Input.X * 60.f, 0.f), DeltaTime, AimRotationLerpSpeed);
		BeetleRidingComponent.AimSpaceValue = FVector2D(AimRotation.Yaw, AimRotation.Pitch);

		const FTransform TurretRootTransform = BeetleRidingComponent.Beetle.SplineFollowerComponent.GetSplineTransform(true);
		const FVector TurretUpDelta = (TurretRootTransform.Rotation.UpVector * 700.f); 
		const FVector TurretForwardDeltaDirection = AimRotation.Compose(TurretRootTransform.Rotator()).ForwardVector; 
		const FVector TurretForwardDelta = TurretForwardDeltaDirection * AimWidgetFrustrumClamp;

		FVector AimWorldLocation = TurretRootTransform.Location;
		AimWorldLocation += TurretUpDelta;
		AimWorldLocation += TurretForwardDelta;

		CurrentAimWorldLocation = AimWorldLocation;

		// System::DrawDebugSphere(CurrentAimWorldLocation, 100.f, 32.f);

		// Setup TargetData
		FMatchTargetData TargetData;

		// Get AutoAim Target
		const FVector AimDirection = (CurrentAimWorldLocation - Player.ViewLocation).GetSafeNormal(); 
		FAutoAimLine Aim = GetAutoAimForTargetLine(
			Player,
			Player.ViewLocation,
			AimDirection,
			0.f,
			AimTraceLength,
			bCheckVisibility = false 
		);

		if (Aim.bWasAimChanged)
		{
			bHasTarget = true;

			TargetData.bHoming = true;
			TargetData.bAutoAim = true;

			TargetData.TraceStart = Aim.AimLineStart;
			TargetData.TraceEnd = Aim.AimLineStart + Aim.AimLineDirection * AimTraceLength;

			TargetData.SetTargetLocation(
				// Aim.AutoAimedAtPoint,
				Aim.AutoAimedAtComponent.GetWorldLocation(),
				Aim.AutoAimedAtComponent,
				NAME_None
			);
		}
		else
		{
			bHasTarget = false;

			const FVector WeaponTraceStart = Wielder.MatchWeapon.Mesh.GetSocketLocation(
				GetMatchWeaponSocketNameFromDefinition(EMatchWeaponSocketDefinition::StartWeaponTraceSocket)
			);

			const FVector CameraTraceEnd = Player.ViewLocation + (AimDirection * AimTraceLength);
			const FVector CameraTraceStart = FMath::ClosestPointOnInfiniteLine(
				Player.ViewLocation,
				CameraTraceEnd,
				WeaponTraceStart
			);

			// Auto aim failed. Lets do our own trace.
			FHitResult CameraHit;
			if(RayTrace( CameraTraceStart, CameraTraceEnd, CameraHit))	
			{
				TargetData.bHoming = true;

				TargetData.TraceStart = CameraTraceStart;
				TargetData.TraceEnd = CameraTraceEnd;

//				System::DrawDebugPoint(CameraHit.ImpactPoint, 20.f, Duration = 10.f);

				TargetData.SetTargetLocation(
					CameraHit.ImpactPoint,
					CameraHit.Component,
					CameraHit.BoneName
				);
			}
			else
			{
				TargetData.TraceStart = WeaponTraceStart;
				TargetData.TraceEnd = CameraHit.TraceEnd;
				// TargetData.TraceEnd = TurretRootTransform.GetLocation();
				// TargetData.TraceEnd += TurretUpDelta;
				// TargetData.TraceEnd += TurretForwardDeltaDirection * AimTraceLength;
			}
		}

		Wielder.TargetData = TargetData;

		const FVector TargetAimLocation = Wielder.TargetData.GetTargetLocation();

		// System::DrawDebugSphere(TargetAimLocation, 100.f, 32.f);

		if(Wielder.TargetData.IsAutoAiming())
		{
			LoseAutoAimSnapTime = 0.5f; // 0.25f
			GainAutoAimSnapTime = FMath::Max(GainAutoAimSnapTime - DeltaTime, 0.f);
			AccCurrentAimWorldLocation.AccelerateTo(TargetAimLocation, GainAutoAimSnapTime, DeltaTime);
			CurrentAimWorldLocation = AccCurrentAimWorldLocation.Value;
		}
		else
		{
			GainAutoAimSnapTime = 0.5f; //0.25f
			LoseAutoAimSnapTime = FMath::Max(LoseAutoAimSnapTime - DeltaTime, 0.f);
			AccCurrentAimWorldLocation.AccelerateTo(CurrentAimWorldLocation, LoseAutoAimSnapTime, DeltaTime);
			CurrentAimWorldLocation = AccCurrentAimWorldLocation.Value;
		}

	}

	void AddAimWidget()
	{
		if (!CrossHairWidget.IsValid())
			return;

		CrossHairWidgetInstance = Cast<UMatchCrosshairWidget>(Player.AddWidget(CrossHairWidget));
	}

	void RemoveAimWidget()
	{
		if (!CrossHairWidget.IsValid())
			return;

		Player.RemoveWidget(CrossHairWidgetInstance);
	}
	bool RayTrace(FVector Start, FVector End, FHitResult& OutHit)
	{
		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Reserve(Wielder.Matches.Num() + 2);
		for (AActor IterMatch : Wielder.Matches)
			ActorsToIgnore.Add(IterMatch);
		ActorsToIgnore.Add(Player);
		ActorsToIgnore.Add(Wielder.GetMatchWeapon());

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
	}

}