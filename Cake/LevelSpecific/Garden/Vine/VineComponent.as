import Cake.LevelSpecific.Garden.Vine.Vine;
import Cake.LevelSpecific.Garden.Vine.VineAimWidget;
import Cake.LevelSpecific.Garden.Vine.VineAttachmentPoint;
import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Peanuts.Animation.Features.Garden.LocomotionFeatureVineStrafeMovement;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;

bool IsAimingWithVine(AHazePlayerCharacter Player)
{
	auto VineComp = UVineComponent::Get(Player);
	if(VineComp == nullptr)
		return false;

	return VineComp.bAiming;
}

UVineImpactComponent GetVineImpactComponent(AHazePlayerCharacter Player)
{
	auto VineComp = UVineComponent::Get(Player);
	if(VineComp == nullptr)
		return nullptr;

	return VineComp.VineImpactComponent;
}

struct FVineHitResult
{
	UPROPERTY()
	UVineImpactComponent ImpactComponent;

	UPROPERTY()
	bool bBlockingHit;

	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	FVector ImpactNormal;
}

event void FOnVineStartRetracting(FVineHitResult VineHit);

EVineActiveType GetVineActiveType(AHazePlayerCharacter Player)
{
	UVineComponent VineComp = UVineComponent::Get(Player);
	return VineComp.VineActiveType;
}

void ForceReleaseVineIfAttachedToImpactComponent(UVineImpactComponent FromImpact)
{
	UVineComponent VineComp = UVineComponent::Get(Game::GetCody());
	if(VineComp == nullptr)
		return;
		
	if(VineComp.VineImpactComponent != FromImpact)
		return;

	VineComp.StartRetracting(FromImpact);
}

UCLASS(Abstract, HideCategories = "ComponentTick Activation Cooking ComponentReplication Variable Tags AssetUserData Collision")
class UVineComponent : UStaticMeshComponent
{
	UPROPERTY(Category = "Vine")
	FName AttachPoint = n"Hat1";

	UPROPERTY(Category = "Vine")
	UNiagaraSystem SpawnEffect;

	UPROPERTY(Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset AimCameraSettingsDefault;

	UPROPERTY(Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset ActiveVineCameraSettings;

	UPROPERTY(Category = "Vine")
	ULocomotionFeatureVineStrafeMovement VineAnimFeature;

	UPROPERTY(Category = "Vine")
	ETraceTypeQuery VineTraceType;

	UPROPERTY(Category = "Attach")
	UForceFeedbackEffect AttachForceFeedback;

	UPROPERTY(Category = "Attach")
	TSubclassOf<UCameraShakeBase> AttachCamShake;

	UPROPERTY(Category = "Vine")
	TSubclassOf<AVine> VineClass;

	UPROPERTY(Category = "Vine")
	float VineActivationDelayTime = 0.08f;

	UPROPERTY(Category = "Vine")
	float WhipExtendSpeed = 17000;

	UPROPERTY(Category = "Vine")
	float AttachExtendSpeed = 18000;

	// Time: the time that the extending has been active. Value; the multiplier amount
	UPROPERTY(Category = "Vine")
	FRuntimeFloatCurve ExtendSpeedMultiplier;

	UPROPERTY(Category = "Vine")
	float RetractSpeed = 15000;

	// Time: the time that the retracting has been active. Value; the multiplier amount
	UPROPERTY(Category = "Vine")
	FRuntimeFloatCurve RetractSpeedMultiplier;

	UPROPERTY(Category = "Vine", meta = (InlineEditConditionToggle))
	bool bUseRetractByDistaneAlphaMultiplier = false;

	// This applies to the 'RetractSpeedMultiplier * RetractSpeed'. The alpha value is 1 when max extended
	UPROPERTY(Category = "Vine", meta = (EditCondition = "bUseRetractByDistaneAlphaMultiplier"))
	FRuntimeFloatCurve RetractByDistaneAlphaMultiplier;


	UPROPERTY(Category = "Vine", meta = (InlineEditConditionToggle))
	bool bUseRetractByImpactDistaneAlphaMultiplier = false;

	/* This applies to the 'RetractSpeedMultiplier * RetractSpeed'. 
		The time is the alpha value when the impact triggers. the alpha only updates when the impact happens 
		The alpha value is 1 when max extended */
	UPROPERTY(Category = "Vine", meta = (EditCondition = "bUseRetractByImpactDistaneAlphaMultiplier"))
	FRuntimeFloatCurve RetractByImpactDistaneAlphaMultiplier;

	UPROPERTY(Category = "Aim")
	TSubclassOf<UVineAimWidget> AimWidgetClass;

	UPROPERTY(Category = "Whip")
	TSubclassOf<UCameraShakeBase> WhipCamShake;

	UPROPERTY(Category = "Whip")
	UForceFeedbackEffect WhipForceFeedback;

	UPROPERTY(Category = "Whip")
	float MaximumDistance = 4500.f;

	UPROPERTY(Category = "Example Events")
	FOnVineStartRetracting OnStartRetractingEvent;

	AVine VineActor;

	private AHazePlayerCharacter Player;
	private AVineAttachmentPoint VineAttachmentPoint;
	UVineAimWidget CurrentWidget;


	private UVineImpactComponent CurrentImpactComponent;
	private FHitResult AsyncTraceResult;
	private int AsyncTraceStatus = 0;
	private FVector LastTraceToLocation;

	// Animation Param
	UPROPERTY(NotEditable)
	bool bAiming = false;

	// Animation Param
	UPROPERTY(NotEditable)
	bool bHasValidTarget = false;

		
	// Animation Param
	UPROPERTY(NotEditable)
	EVineActiveType VineActiveType = EVineActiveType::Inactive;

	bool bCanActivateVine = false;
	float CurrentActiveTime = 0;
	private float CurrentExtendTime = 0;
	private float CurrentRetractTime = 0;
	private float ImpactDistanceAlpha = 0;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		AttachToComponent(Player.Mesh, AttachPoint, EAttachmentRule::KeepRelative);
		VineActor = Cast<AVine>(SpawnPersistentActor(VineClass));
		VineAttachmentPoint = Cast<AVineAttachmentPoint>(SpawnPersistentActor(AVineAttachmentPoint::StaticClass()));
		
		VineActor.AttachRootComponentTo(Player.Mesh, VineActor.AttachPoint, EAttachLocation::SnapToTarget);
		VineActor.Mesh.AddTickPrerequisiteComponent(Player.Mesh);
		VineActor.DeactivateVine();
		VineActor.VineTargetPoint = VineAttachmentPoint;

		CurrentWidget = Cast<UVineAimWidget>(Player.AddWidget(AimWidgetClass));
		CurrentWidget.SetVisibility(ESlateVisibility::Collapsed);

		Player.AddLocomotionFeature(VineAnimFeature);
		SetComponentTickEnabled(false);
		SetVisibility(false);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Player.RemoveLocomotionFeature(VineAnimFeature);
		if(CurrentWidget != nullptr)
		{
			CurrentWidget.SetVisibility(ESlateVisibility::Collapsed);
			Player.RemoveWidget(CurrentWidget);
			CurrentWidget = nullptr;
		}

		if(VineActor != nullptr)
		{
			VineActor.DetachRootComponentFromParent();
			VineActor.DestroyActor();
			VineActor = nullptr;
		}

		if(VineAttachmentPoint != nullptr)
		{
			VineAttachmentPoint.DestroyActor();
			VineAttachmentPoint = nullptr;
		}

	}

	void SetVineAnimationType(EVineActiveType Type)
	{
		VineActiveType = Type;
		if(Type == EVineActiveType::PreExtending)
			VineActor.VineActiveType = EVineActiveType::Inactive;
		else
			VineActor.VineActiveType = Type;
	}

	bool CanAttachToTarget() const
	{
		if(GetValidVineImpactComponent() == nullptr)
			return false;

		if(CurrentImpactComponent.AttachmentMode == EVineAttachmentType::Whip)
			return false;

		return true;
	}
	
	void StartRetracting(UVineImpactComponent CurrentImpactPoint)
	{
		if(VineActiveType == EVineActiveType::Retracting)
			return;

		if(VineActiveType == EVineActiveType::Inactive)
			return;

		ImpactDistanceAlpha = FMath::Min(VineActor.GetDistSqToStartLocation() / FMath::Square(MaximumDistance), 1.f) ;
		ReleaseAttachmentPoint();
		SetVineAnimationType(EVineActiveType::Retracting);
		ClearVineHitResult();
		if(CurrentImpactPoint != nullptr)
		{
			CurrentImpactPoint.VineDisconnected();
		}
	}

	void UpdateVineTraceHitResult(UVineImpactComponent WantedInteractionPoint, bool bWithDebug)
	{
		// We cant trace while waiting for the result
		if(AsyncTraceStatus == -1)
			return;

		if(CurrentImpactComponent != nullptr && !CurrentImpactComponent.ShouldUpdateTrace())
		{
			if(!CurrentImpactComponent.IsValidTarget())
			{
				ClearVineHitResult();
			}
		}

		if(CurrentImpactComponent != nullptr 
			&& WantedInteractionPoint != nullptr 
			&& WantedInteractionPoint != CurrentImpactComponent)
		{
			ClearVineHitResult();
		}

		const FVector TraceFrom = GetTraceStartPoint();

		// We have an interaction point and we want to hit that
		if(WantedInteractionPoint != nullptr && WantedInteractionPoint.AttachmentMode != EVineAttachmentType::HitLocation)
		{
			LastTraceToLocation = WantedInteractionPoint.GetTransformFor(Player).Location;
			LastTraceToLocation += (LastTraceToLocation - TraceFrom).GetSafeNormal() * 25.f; // safeyty amount so we hit the shape
		}
		else
		{
			LastTraceToLocation = TraceFrom + (Player.ViewRotation.Vector() * MaximumDistance);
		}

		FHazeTraceParams TraceParams = GetVineTraceParams(TraceFrom, LastTraceToLocation, bWithDebug);
		auto TraceComponent = UHazeAsyncTraceComponent::GetOrCreate(Player);

		FHazeAsyncTraceComponentCompleteDelegate Delegate;
		Delegate.BindUFunction(this, n"TraceDone"); 
		
		AsyncTraceStatus = -1;
		TraceComponent.TraceSingle(TraceParams, this, n"VineTrace", Delegate);
	}

	UFUNCTION(NotBlueprintCallable)
	private void TraceDone(UObject Instigator, FName TraceId, TArray<FHitResult> Obstructions)
	{
		// We have cleaned the trace while waiting for a async trace
		if(AsyncTraceStatus == 2)
			AsyncTraceStatus = 0;

		// We are not waiting for any tracing do be complete
		if(AsyncTraceStatus != -1)
			return;

		/* Some impact components are badlyplaces outside collsions, so no collision sometimes need to be valid collisions */
		const bool bNoImpactIsValidImpact = CurrentImpactComponent != nullptr && VineActiveType == EVineActiveType::ActiveAndLocked;
	

		if(Obstructions.Num() == 0)
		{
			if(!bNoImpactIsValidImpact)
			{
				ClearVineHitResult();
				AsyncTraceStatus = 1;
				AsyncTraceResult = FHitResult(nullptr, nullptr, LastTraceToLocation, (LastTraceToLocation - Owner.GetActorLocation()).GetSafeNormal());	
			}
		}
		else
		{
			if(Obstructions[0].Actor != nullptr)
			{
				auto ImpactComponent = UVineImpactComponent::Get(Obstructions[0].Actor);
				if(ImpactComponent != nullptr && ImpactComponent.IsValidTarget())
					CurrentImpactComponent = ImpactComponent;
				else if(!bNoImpactIsValidImpact)
					ClearVineHitResult();
			}

			AsyncTraceStatus = 1;
			AsyncTraceResult = Obstructions[0];
		}

		if(CurrentImpactComponent == nullptr)
		{
			CurrentWidget.MakeInvalid();
		}
		else
		{
			if(CurrentImpactComponent.AttachmentMode == EVineAttachmentType::HitLocation)
				CurrentWidget.MakeAutoAim(AsyncTraceResult.ImpactPoint);
			else
				CurrentWidget.MakeAutoAim(CurrentImpactComponent.GetTransformFor(Player).Location);
		}
	}

	void ClearVineHitResult()
	{
		CurrentImpactComponent = nullptr;
		CurrentWidget.MakeInvalid();
		if(AsyncTraceStatus == -1)
			AsyncTraceStatus = 2;
		else
			AsyncTraceStatus = 0;
	}

	private FHazeTraceParams GetVineTraceParams(FVector From, FVector To, bool bWithDebug) const
	{
		TArray<AActor> ActorsToIgnore;	
		ActorsToIgnore.Add(Game::GetMay());
		ActorsToIgnore.Add(Game::GetCody());

		FHazeTraceParams Trace;
		Trace.InitWithTraceChannel(VineTraceType);
		Trace.IgnoreActors(ActorsToIgnore);
		Trace.From = From;
		Trace.To = To;
		Trace.DebugDrawTime = bWithDebug ? 0.f : -1.f;
		Trace.SetToLineTrace();

		return Trace;
	}

	UVineImpactComponent GetVineImpactComponent() const property
	{
		return CurrentImpactComponent;
	}

	UVineImpactComponent GetValidVineImpactComponent() const property
	{
		if(CurrentImpactComponent == nullptr)
			return nullptr;
		if(!CurrentImpactComponent.IsValidTarget())
			return nullptr;
		return CurrentImpactComponent;
	}

	bool GetVineImpact(FVineHitResult& Out) const
	{	
		if(AsyncTraceStatus == 1 || AsyncTraceStatus == -1)
		{		
			Out.bBlockingHit = AsyncTraceResult.bBlockingHit;
			Out.ImpactComponent = GetValidVineImpactComponent();
			Out.ImpactLocation = AsyncTraceResult.ImpactPoint;
			Out.ImpactNormal = AsyncTraceResult.ImpactNormal;
			return true;
		}

		return false;
	}
	
	void UpdateVineHitResultFromReplication(FVineHitResult Replication)
	{
		AsyncTraceStatus = 1;
		CurrentImpactComponent = Replication.ImpactComponent;
		AActor ReplicatedOwner = CurrentImpactComponent != nullptr ? CurrentImpactComponent.GetOwner() : nullptr;
		AsyncTraceResult = FHitResult(ReplicatedOwner, nullptr, Replication.ImpactLocation, Replication.ImpactNormal);
		bHasValidTarget =  CurrentImpactComponent != nullptr;
	}
	
	void LockAttachmentPoint()
	{
		// Offset the head a little bit so we see more of the mesh
		FVector ImpactLocation = AsyncTraceResult.ImpactPoint;
		FVector ImpactNormal = AsyncTraceResult.Normal;
		
		// We offset a little bit so the vine head is visible
		ImpactLocation += ImpactNormal * 20.f;

	 	if(CurrentImpactComponent != nullptr)
		{
			VineAttachmentPoint.AttachToComponent(CurrentImpactComponent);
			if(CurrentImpactComponent.AttachmentMode != EVineAttachmentType::HitLocation)
				ImpactLocation = CurrentImpactComponent.GetTransformFor(Player).Location;
		}
		else
		{
			VineAttachmentPoint.DetachRootComponentFromParent();	
		}	

		VineAttachmentPoint.SetActorLocation(ImpactLocation);
	}

	void ReleaseAttachmentPoint()
	{
		VineAttachmentPoint.AttachToComponent(GetOwner().RootComponent);
	}

	FVector GetTraceStartPoint() const
	{
		FVector TraceFrom = Player.ViewLocation;
		TraceFrom += Player.ViewRotation.ForwardVector * TraceFrom.Dist2D(Player.GetActorLocation(), Player.GetMovementWorldUp());
		return TraceFrom;
	}

	FVector GetTargetPoint() const
	{
		return VineAttachmentPoint.GetActorLocation();
	}

	void StartAiming()
	{
		ApplyVineCameraSettings(0.5f);
		bAiming = true;
		CurrentWidget.OnAimStarted();
		CurrentWidget.SetVisibility(ESlateVisibility::Visible);
	}

	void StopAiming()
	{
		ClearVineCameraSettings();
		bAiming = false;
		CurrentWidget.SetVisibility(ESlateVisibility::Collapsed);
	}

	private UHazeCameraSpringArmSettingsDataAsset CustomCameraDataAsset;
	UFUNCTION()
	void SetCustomAimCameraSettings(UHazeCameraSpringArmSettingsDataAsset Asset)
	{
		CustomCameraDataAsset = Asset;
	}

	UHazeCameraSpringArmSettingsDataAsset GetAimCameraSettings() const property
	{
		if(CustomCameraDataAsset != nullptr)
			return CustomCameraDataAsset;

		return AimCameraSettingsDefault;
	}

	void ApplyVineCameraSettings(float BlendTime)
	{
		Player.ClearCameraSettingsByInstigator(this);

		FHazeCameraBlendSettings CamBlend;
		CamBlend.BlendTime = BlendTime;
		Player.ApplyCameraSettings(AimCameraSettings, CamBlend, this);
	}

	void ClearVineCameraSettings()
	{
		Player.ClearCameraSettingsByInstigator(this);
	}

	void ClearVineValues()
	{
		CurrentActiveTime = 0;
		CurrentExtendTime = 0;
		CurrentRetractTime = 0;
	}

	bool UpdateExtending(float DeltaTime)
	{
		if(VineActor == nullptr)
			return false;
		
		const float Multiplier = ExtendSpeedMultiplier.GetFloatValue(CurrentExtendTime, 1.f);
		CurrentExtendTime += DeltaTime;
		CurrentRetractTime = 0;

		const float ExtendSpeed = VineActor.IsWhipping() ? WhipExtendSpeed : AttachExtendSpeed;
		return VineActor.UpdateExtending(DeltaTime, ExtendSpeed * Multiplier);
	}

	bool UpdateRetracting(float DeltaTime)
	{
		if(VineActor == nullptr)
			return false;

		float Multiplier = RetractSpeedMultiplier.GetFloatValue(CurrentRetractTime, 1.f);
		
		if(bUseRetractByImpactDistaneAlphaMultiplier)
		{
			Multiplier *= RetractByImpactDistaneAlphaMultiplier.GetFloatValue(ImpactDistanceAlpha, Multiplier);
		}

		if(bUseRetractByDistaneAlphaMultiplier)
		{
			const float DistanceAlpha = FMath::Min(VineActor.GetDistSqToStartLocation() / FMath::Square(MaximumDistance), 1.f) ;
			Multiplier *= RetractByDistaneAlphaMultiplier.GetFloatValue(DistanceAlpha, Multiplier);
		}

		CurrentExtendTime = 0;
		CurrentRetractTime += DeltaTime;

		return VineActor.UpdateRetracting(DeltaTime, RetractSpeed * Multiplier);
	}
}