import Cake.LevelSpecific.Music.Cymbal.CymbalImpactComponent;
import Cake.LevelSpecific.Music.Singing.SongOfLife.SongOfLifeComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophoneHeadState;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophoneTargetingComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophoneEyeColorInfo;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophoneSettings;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MurderMicrophoneDeathEffect;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophoneMovementComponent;
import Vino.Camera.Components.WorldCameraShakeComponent;

bool ShouldEnterHypnosis(AActor SnakeActor)
{
	AMurderMicrophone Snake = Cast<AMurderMicrophone>(SnakeActor);
	if(Snake != nullptr)
		return Snake.ShouldEnterHypnosis();

	return false;
}

bool IsInHypnosis(AActor SnakeActor)
{
	AMurderMicrophone Snake = Cast<AMurderMicrophone>(SnakeActor);
	if(Snake != nullptr)
		return Snake.IsInHypnosis();

	return false;
}

bool IsSnakeInsideChaseArea(AActor SnakeActor)
{
	AMurderMicrophone Snake = Cast<AMurderMicrophone>(SnakeActor);

	if(Snake == nullptr)
		return false;

	return Snake.IsSnakeInsideChaseRadius();
}

bool IsLocationInsideChaseRange(AActor SnakeActor, FVector InLocation)
{
	AMurderMicrophone Snake = Cast<AMurderMicrophone>(SnakeActor);
	if(Snake != nullptr)
	{
		return Snake.IsLocationInsideChaseRange(InLocation);
	}

	return false;
}

bool IsLocationInsideAggressiveRange(AActor SnakeActor, FVector InLocation)
{
	AMurderMicrophone Snake = Cast<AMurderMicrophone>(SnakeActor);
	if(Snake != nullptr)
	{
		return Snake.IsLocationInsideAggressiveRange(InLocation);
	}

	return false;
}

class UMurderMicrophoneVisualizerComponent : UActorComponent {}

#if EDITOR

class UMurderMicrophoneVisualizerDummy : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UMurderMicrophoneVisualizerComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        if (!ensure((Component != nullptr) && (Component.Owner != nullptr)))
			return;

		AMurderMicrophone Snake = Cast<AMurderMicrophone>(Component.Owner);

		if(!ensure(Snake != nullptr))
			return;

        DrawWireSphere(Snake.SnakeHeadControlPoint, 100.0f, FLinearColor::Green);

		for(FVector P : Snake.SplinePath)
		{
			DrawPoint(P, FLinearColor::Green);
		}

		DrawWireSphere(Snake.SplineControlPointTop, 100.0f, FLinearColor::Red);
		DrawWireSphere(Snake.ActorLocation, Snake.CoreRevealRange, FLinearColor::Green, 6.0f);

		Snake.PreviewSpline();
		Snake.DebugDrawSplinePath();
	}
}

#endif // EDITOR

event void FMurderMicrophoneSignature();

settings MurderMicrophoneSettingsDefault for UMurderMicrophoneSettings
{

}

enum EMurderMicrophoneBodyTravelType
{
	HeadToCore,
	CoreToHead
}

enum EMurderMicrophoneDetailLevel
{
	High,
	Medium,
	Low,
	Default
}

struct FMurderMicrophoneBodyTravel
{
	private FVector _LocationCurrent;
	private float _Alpha = 0.0f;
	private float _Direction = 0.0f;
	private AMurderMicrophone Snake;
	private EMurderMicrophoneBodyTravelType _TravelType;
	
	void StartTravel(AMurderMicrophone InSnake, EMurderMicrophoneBodyTravelType InTravelType)
	{
		Snake = InSnake;
		_TravelType = InTravelType;

		if(_TravelType == EMurderMicrophoneBodyTravelType::HeadToCore)
		{
			_Direction = 1.0f;

			if(ShouldSetAlpha())
				_Alpha = 0.0f;
		}
		else if(_TravelType == EMurderMicrophoneBodyTravelType::CoreToHead)
		{
			_Direction = -1.0f;

			if(ShouldSetAlpha())
				_Alpha = 1.0f;
		}
	}

	float GetAlpha() const property
	{
		return _Alpha;
	}

	private bool ShouldSetAlpha()
	{
		return FMath::IsNearlyZero(_Alpha) || FMath::IsNearlyEqual(_Alpha, 1.0f);
	}

	void Travel(FVector& OutLocation, bool& bDone, float DeltaTime, float InterSpeed)
	{
		if(!devEnsure(Snake != nullptr, "No snake is present, did you forget to call StartTravel?"))
			return;

		bDone = false;
		_Alpha = FMath::Clamp(_Alpha + ((InterSpeed *_Direction) * DeltaTime), 0.0f, 1.0f);
		const FVector Destination = Snake.CordExitWorldLocation;
		const FVector Origin = Snake.SnakeCordLocation;
		const FVector ControlPointA = Snake.SnakeHeadControlPoint;
		const FVector ControlPointB = Snake.SplineControlPointBottom;
		const FVector ControlPointC = Snake.SplineControlPointTop;
		OutLocation = Math::GetPointOnQuarticBezierCurveConstantSpeed(Origin, ControlPointA, ControlPointB, ControlPointC, Destination, _Alpha);

		if(_TravelType == EMurderMicrophoneBodyTravelType::CoreToHead)
		{
			if(FMath::IsNearlyZero(_Alpha))
				bDone = true;
		}
		else if(_TravelType == EMurderMicrophoneBodyTravelType::HeadToCore)
		{
			if(FMath::IsNearlyEqual(_Alpha, 1.0f))
				bDone = true;
		}
	}
}

class AMurderMicrophone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	USceneComponent HeadOffset;

	UPROPERTY(DefaultComponent, Attach = HeadOffset)
	UHazeCharacterSkeletalMeshComponent HeadMesh;
	default HeadMesh.CollisionProfileName = n"BlockOnlyPlayerCharacter";

	UPROPERTY(DefaultComponent, Attach = HeadMesh, AttachSocket = Tongue2)
	UCymbalImpactComponent HeadCymbalImpact;
	default HeadCymbalImpact.bHideCymbalWidget = true;

	UPROPERTY(DefaultComponent, Attach = HeadMesh, AttachSocket = Tongue2)
	USongOfLifeComponent SongOfLifeComp;
	default SongOfLifeComp.RelativeLocation = FVector(0.0f, 0.0f, 150.0f);
	default SongOfLifeComp.WidgetLocalOffset = FVector(200.0f, 0.0f, -150.0f);
	default SongOfLifeComp.bEnableVFXPreview = false;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent ReplicatedLocation;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UMurderMicrophoneMovementComponent MoveComp;

	UPROPERTY(DefaultComponent, Attach = HeadMesh, AttachSocket = Tongue2)
	UForceFeedbackComponent ForceFeedbackComp;

	UPROPERTY(DefaultComponent, Attach = HeadMesh, AttachSocket = Tongue2)
	UWorldCameraShakeComponent CamShakeComp;

	UPROPERTY(Category = Settings)
	UMurderMicrophoneSettings SleepingSettings;
	UPROPERTY(Category = Settings)
	UMurderMicrophoneSettings SuspiciousSettings;
	UPROPERTY(Category = Settings)
	UMurderMicrophoneSettings AggressiveSettings;
	UPROPERTY(Category = Settings)
	UMurderMicrophoneSettings RetreatSettings;
	UPROPERTY(Category = Settings)
	UMurderMicrophoneSettings HypnosisSettings;
	UPROPERTY(Category = Settings)
	UMurderMicrophoneSettings DeathSettings;
	UPROPERTY(Category = Settings)
	UMurderMicrophoneSettings EatPlayerSettings;

	UMurderMicrophoneSettings SnakeSettings;

	UPROPERTY(Category = "Setup|Cord", meta = (MakeEditWidget))
	FVector CordInsideLocation = FVector(0.0f, 0.0f, 420.0f);
	UPROPERTY(Category = "Setup|Cord", meta = (MakeEditWidget))
	FVector CordExitLocation = FVector(0.0f, 0.0f, 435.0f);
	UPROPERTY(Category = "Setup|Cord", meta = (MakeEditWidget, DisplayName = "CordControlPointTop"))
	FVector Local_CordControlPointTop = FVector(-210.0f, 0.0f, 600.0f);
	UPROPERTY(Category = "Setup|Cord", meta = (MakeEditWidget, DisplayName = "CordControlPointBottom"))
	FVector Local_CordControlPointBottom = FVector(-210.0f, 0.0f, 600.0f);

	UPROPERTY(Category = "VOBark")
	UFoghornVOBankDataAssetBase FoghornDataAsset;

	FVector CordBottomOffset;

	float ControlPointTopOffset = 0.0f;

	FVector GetCordInsideWorldLocation() const property { return ActorTransform.TransformPosition(CordInsideLocation); }
	FVector GetCordExitWorldLocation() const property { return ActorTransform.TransformPosition(CordExitLocation); }

	UPROPERTY()
	TSubclassOf<UMurderMicrophoneDeathEffect> DeathEffect;
	default DeathEffect = UMurderMicrophoneDeathEffect::StaticClass();

	UPROPERTY()
	UStaticMesh DestroyedCoreMesh;
	private UStaticMesh DefaultCoreMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MicSpool;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeLazyPlayerOverlapComponent StasisField;

	UPROPERTY(DefaultComponent, Attach = StasisField)
	UNiagaraComponent StasisFieldVFX;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> StasisFieldDeathEffect;

	UPROPERTY(DefaultComponent, Attach = MicSpool)
	UStaticMeshComponent WeakPoint;

	UPROPERTY(DefaultComponent, Attach = WeakPoint)
	UCymbalImpactComponent CymbalImpact;
	default CymbalImpact.bCanBeTargeted = false;

	UPROPERTY(DefaultComponent, Attach = CymbalImpact)
	UAutoAimTargetComponent AutoAim;

	UPROPERTY(DefaultComponent, Attach = MicSpool)
	UStaticMeshComponent WeakPointGuard01;

	UPROPERTY(DefaultComponent, Attach = MicSpool)
	UStaticMeshComponent WeakPointGuard02;

	UPROPERTY(Category = Animation)
	UAnimSequence BiteAnim;

	UPROPERTY(Category = Animation)
	UAnimSequence SwallowAnim;

	UPROPERTY(DefaultComponent)
	UHazeCableComponent BodyComponent;
	default BodyComponent.bAttachEnd = false;
	default BodyComponent.bAttachStart = false;
	default BodyComponent.bSimulatePhysics = false;
	default BodyComponent.bGenerateOverlapEvents = false;
	default BodyComponent.CollisionProfileName = n"NoCollision";
	default BodyComponent.CableWidth = 80.0f;
	default BodyComponent.NumSides = 8;
	// Don't touch this, we will set tiling in the material instead.
	default BodyComponent.TileMaterial = 1.0f;

	FHazeQuarticBezierCurve QuarticBezierCurve;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UMurderMicrophoneTargetingComponent TargetingComponent;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 125000.f;

	UPROPERTY(DefaultComponent)
	UHazeAsyncTraceComponent AsyncTrace;

	UPROPERTY(DefaultComponent, Attach = HeadMesh)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeAkComponent ElectricityBallAkComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;

	UPROPERTY(DefaultComponent, NotEditable)
	UMurderMicrophoneVisualizerComponent Visualizer;

	// Core will be revealed when snake is hypnotized and outside this range.
	UPROPERTY()
	float CoreRevealRange = 1.0f;

	float GetCoreRevealRangeSq() const property { return FMath::Square(CoreRevealRange); }

	const float PitchLimit = 50.0f;

	FRotator GetClampedFacingRotation(FRotator InFacingRotation)
	{
		FRotator Rot = InFacingRotation;
		Rot.Pitch = FMath::Clamp(Rot.Pitch, -PitchLimit, PitchLimit);
		return Rot;
	}

	FVector GetClampedFacingDirection(FVector InFacingDirection)
	{
		return GetClampedFacingRotation(InFacingDirection.Rotation()).Vector();
	}

	float MovementVelocity = 0.0f;

	private float _StartingDistanceToCore = 1.0f;
	float GetStartingDistanceToCore() const property { return _StartingDistanceToCore; }

	// The lower the value, the more smooth the cord spline will be displayed, and more cpu will be drained.
	UPROPERTY(Category = Cord)
	float CordDetailLevel = 35.0f;
	private float LastCordDetailLevel = 0.0f;
	float CordMaxLength = 7000.0f;
	float DefaultTileMaterial = 8.0f;
	UPROPERTY(NotEditable, NotVisible)
	float CurrentTileMaterial = 8.0f;
	float TileMaterialLengthDefault = 900.0f;
	TArray<FVector> SplinePath;

	UPROPERTY()
	EMurderMicrophoneDetailLevel DetailSettings = EMurderMicrophoneDetailLevel::Low;

	UPROPERTY()
	float HeadControlPointLength = 700.0f;

	UPROPERTY()
	bool bEnableBodyAlignment = false;

	FVector WiggleOffset;

	UPROPERTY(meta = (EditCondition="bEnableBodyAlignment == true", EditConditionHides))
	float BodyAlignmentLength = 1300.0f;

	UPROPERTY()
	bool bEnableBodyWiggle = true;

	UPROPERTY(meta = (EditCondition="bEnableBodyWiggle == true", EditConditionHides, ClampMin = 0.0))
	float WiggleLengthModifier = 1.0f;

	// When Mayis outside of chase range and this range away from the snake, snake will exit hypnosis.
	UPROPERTY(Category = Hypnosis)
	float HypnosisMaxRange = 3000.0f;
	float GetHypnosisMaxRangeSq() const property { return FMath::Square(HypnosisMaxRange); }

	int NumSplinePointsCurrent = 0;
	// Offset size in list whenever required by this value
	int NumSplinePointsOffset = 10;

	UPROPERTY(Category = VFX)
	UNiagaraSystem CoreExplosionFX;

	UPROPERTY(Category = VFX)
	UNiagaraSystem HeadExplosionFX;

	UPROPERTY(Category = VFX)
	UNiagaraSystem CordFuseFX;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ExplosionEvent;
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent HeadExplosionEvent;
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OpenBaseEvent;
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CloseBaseEvent;
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ElectricityBallStart;
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ElectricityBallEnd;
	UPROPERTY(Category = "Audio")
	TSubclassOf<UHazeCapability> AudioCapability;

	private FVector _HeadStartLocation;
	private FRotator _HeadStartRotation;

	FVector GetHeadStartLocation() const property { return _HeadStartLocation; }
	FRotator GetHeadStartRotation() const property { return _HeadStartRotation; }

	UPROPERTY(Category = Animation)
	UAnimSequence SwallowMayAnimation;
	UPROPERTY(Category = Animation)
	UAnimSequence SwallowCodyAnimation;
	// Store the animation class if we want to debug-revive the snake.
	private UClass DefaultAnimationClass;
	private FHazeAudioEventInstance CoreAudioEvent;

	// Settings hack to avoid camera snap when the player is attached to the snake while being eaten.
	UPROPERTY(Category = Camera)
	UHazeCameraSpringArmSettingsDataAsset KillCamSettings;

	UPROPERTY()
	FMurderMicrophoneSignature OnRevealWeakPoint;
	UPROPERTY()
	FMurderMicrophoneSignature OnHideWeakPoint;
	UPROPERTY()
	FMurderMicrophoneSignature OnExitHypnosis;
	UPROPERTY()
	FMurderMicrophoneSignature OnMurderMicrophoneCoreDestroyed;
	UPROPERTY()
	FMurderMicrophoneSignature OnMurderMicrophoneDestroyed;

	private bool bIsDestroyed = false;
	private bool bWeakPointRevealed = false;
	private bool bDebugWeakPoint = false;
	private bool bChargeSongOfLife = false;
	private bool bWasCoreRevealed = false;

	UPROPERTY(Category = Debug)
	bool bAlwaysDrawVision = false;

	UPROPERTY()
	bool bHideBase = false;

	bool IsSnakeDestroyed() const { return bIsDestroyed; }

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bIsFlinching = false;

	bool IsAffectedBySongOfLife() const  { return bChargeSongOfLife; }
	
	bool IsInHypnosis() const
	{
		return CurrentState == EMurderMicrophoneHeadState::Hypnosis
		|| CurrentState == EMurderMicrophoneHeadState::ExitHypnosis;
	}

	float SongOfLifeCharge = 0.0f;

	private EMurderMicrophoneHeadState CurrentHeadState = EMurderMicrophoneHeadState::Sleeping;

	UPROPERTY(NotEditable, Category = MurderMicrophone, BlueprintReadOnly)
	bool bKilledPlayer = false;

	bool bSwallowPlayer = false;

	UFUNCTION(BlueprintPure, Category = MurderMicrophone)
	EMurderMicrophoneHeadState GetCurrentState() const property { return CurrentHeadState; }

	// Select references to nearby snakes. Will try to not clip into these friends when moving.
	UPROPERTY()
	TArray<AMurderMicrophone> SnakeFriends;

	// Used when suspicious, retreat etc
	UPROPERTY(Category = EyeColor)
	FLinearColor StandardEyeColor = FLinearColor(1.0f, 1.0f, 1.0f, 1.0f);
	// Used when chasing the player and when eating a player.
	UPROPERTY(Category = EyeColor)
	FLinearColor AggressiveEyeColor = FLinearColor(1500.0f, 0.0f, 0.0f, 1.0f);
	UPROPERTY(Category = EyeColor)
	float EyeColorTransitionSpeed = 4.0f;
	private FLinearColor CurrentEyeColor = FLinearColor(150.0f, 50.0f, 5.4f, 1.0f);

	UPROPERTY(Category = EyeColor)
	float EyeColorIntensity = 2.5f;

	// Used when charging the hypnosis, goes from 0-1 in the curve where 1 is when fully hypnotized.
	UPROPERTY(Category = EyeColor)
	UCurveLinearColor HypnosisEyeColorCurve;
	

	private float ColorTransition = 0.0f;

	private TArray<FMurderMicrophoneEyeColorInfo> EyeColorList;

	//FVector _TargetLocation;

	// Set whenever we are supposed to eat something.
	AHazePlayerCharacter TargetToEat = nullptr;
	AHazePlayerCharacter HypnosisTarget = nullptr;

	private AHazePlayerCharacter _PendingTarget = nullptr;
	bool HasPendingTarget() const { return _PendingTarget != nullptr; }
	AHazePlayerCharacter GetPendingTarget() const property { return _PendingTarget; }
	void ClearPendingTarget()
	{
		_PendingTarget = nullptr;
	}

	private AHazePlayerCharacter _TargetPlayer = nullptr;
	AHazePlayerCharacter GetTargetPlayer() const property { return _TargetPlayer; }
	bool HasTarget() const { return _TargetPlayer != nullptr; }
	private float ChangeTargetElapsed = 0.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		ReplicatedLocation.Value = HeadOffset.WorldLocation;

		if(bHideBase)
		{
			HideBase();
		}
		else
		{
			ShowBase();
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp.Setup(HeadOffset, ActorLocation);

		int OutNumSides = 4;
		float OutCordDetailLevel = 40.0f;
		GetStandardDetailLevel(OutNumSides, OutCordDetailLevel);
		CordDetailLevel = OutCordDetailLevel;
		BodyComponent.OverrideNumSides(OutNumSides);

		LastCordDetailLevel = CordDetailLevel;
		DefaultCoreMesh = MicSpool.StaticMesh;
		ReplicatedLocation.Value = HeadOffset.WorldLocation;
		ApplyDefaultSettings(MurderMicrophoneSettingsDefault);
		SnakeSettings = UMurderMicrophoneSettings::GetSettings(this);
		HeadOffset.DetachFromParent(true);
		ElectricityBallAkComp.DetachFromParent(true);

		SongOfLifeComp.OnStartAffectedBySongOfLife.AddUFunction(this, n"Handle_SongOfLifeBegin");
		SongOfLifeComp.OnStopAffectedBySongOfLife.AddUFunction(this, n"Handle_SongOfLifeEnd");
		
		CymbalImpact.OnCymbalHit.AddUFunction(this, n"Handle_CymbalImpact");
		HeadCymbalImpact.OnCymbalHit.AddUFunction(this, n"Handle_CymbalImpact_Head");

		if(AudioCapability.IsValid())
			AddCapability(AudioCapability);

		DefaultAnimationClass = HeadMesh.AnimClass;

		_HeadStartLocation = HeadOffset.WorldLocation;
		_HeadStartRotation = HeadOffset.WorldRotation;
		MoveComp.SetTargetLocation(HeadOffset.WorldLocation);
		MoveComp.SetTargetFacingRotation(_HeadStartRotation);
		//_TargetLocation = HeadOffset.WorldLocation;

		InitSplinePath();

		AddCapability(n"MurderMicrophoneSleepingCapability");
		AddCapability(n"MurderMicrophoneSuspiciousCapability");
		AddCapability(n"MurderMicrophoneMovementCapability");
		AddCapability(n"MurderMicrophoneAggressiveCapability");
		AddCapability(n"MurderMicrophoneTargetingCapability");
		AddCapability(n"MurderMicrophoneRetreatCapability");
		AddCapability(n"MurderMicrophoneEatPlayerCapability");
		AddCapability(n"MurderMicrophoneHypnosisCapability");
		AddCapability(n"MurderMicrophoneExitHypnosisCapability");
		AddCapability(n"MurderMicrophoneSwallowCapability");
		AddCapability(n"MurderMicrophoneDeathCapability");
		AddCapability(n"MurderMicrophoneBodyAlignmentCapability");
		AddCapability(n"MurderMicrophoneBodyWiggleCapability");

		AddDebugCapability(n"MurderMicrophoneDebugCapability");

		_StartingDistanceToCore = HeadMesh.WorldLocation.DistSquared2D(ActorLocation);

		if(bHideBase)
		{
			HideBase();
		}
		else
		{
			StasisField.OnPlayerBeginOverlap.AddUFunction(this, n"Handle_StasisFieldOverlap");
		}

		for(AMurderMicrophone Friend : SnakeFriends)
		{
			if(Friend == nullptr)
				continue;
			TargetingComponent.AddIgnoreActor(Friend);
		}


	}

    UFUNCTION(NotBlueprintCallable)
    private void Handle_StasisFieldOverlap(AHazePlayerCharacter Player)
    {
		if(!bIsDestroyed && Player != nullptr && Player.HasControl())
		{
#if !RELEASE
			EGodMode GodMode = GetGodMode(Player);
			if(GodMode != EGodMode::Mortal)
				return;
#endif // !RELEASE
			KillPlayer(Player, StasisFieldDeathEffect);
			BP_OnPlayerKilledByStasisField(Player);
		}
    }

	void HideBase()
	{
		MicSpool.SetVisibility(false, true);
		MicSpool.SetCollisionProfileName(n"NoCollision");
		WeakPoint.SetCollisionProfileName(n"NoCollision");
		WeakPointGuard01.SetCollisionProfileName(n"NoCollision");
		WeakPointGuard02.SetCollisionProfileName(n"NoCollision");
		CymbalImpact.SetCymbalImpactEnabled(false);
		AutoAim.Deactivate();
		StasisField.Deactivate();
		StasisFieldVFX.Deactivate();
	}

	void ShowBase()
	{
		MicSpool.SetVisibility(true, true);
		MicSpool.SetCollisionProfileName(n"BlockAllDynamic");
		WeakPoint.SetCollisionProfileName(n"BlockAllDynamic");
		WeakPointGuard01.SetCollisionProfileName(n"BlockAllDynamic");
		WeakPointGuard02.SetCollisionProfileName(n"BlockAllDynamic");
		CymbalImpact.SetCymbalImpactEnabled(true);
		AutoAim.Activate();
		StasisField.Activate();
		StasisFieldVFX.Activate();
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnSnakeAnimationUpdate(UHazeSkeletalMeshComponentBase SnakeMesh)
	{
		UpdateSpline(ActorDeltaSeconds);
	}

	void PreviewSpline()
	{
		InitSplinePath();
		CurrentTileMaterial = GetTargetTileMaterial();
		BodyComponent.SetParticlesFromLocations(SplinePath);
	}

	float GetTargetTileMaterial() const
	{
		float CordTileFrac = CordLengthCurrent / TileMaterialLengthDefault;
		float NewTileMaterial = DefaultTileMaterial * CordTileFrac;
		return NewTileMaterial;
	}

	float GetNumSplinePoints() const
	{
		return CalculateNumSplinePoints() + 2;
	}

	void UpdateEyeColorIntensityAlpha(FVector Origin)
	{
		if(!HasTarget())
		{
			EyeColorIntensityAlpha = 0.0f;
		}
		else
		{
			const float DistanceToTargetSq = FMath::Max(TargetPlayer.ActorLocation.DistSquared2D(Origin), TargetingComponent.AggressiveRangeSq);
			const float Alpha = TargetingComponent.AggressiveRangeSq / DistanceToTargetSq;
			const float Exp = TargetingComponent.AggressiveRange / 750.0f;
			//PrintToScreen("Exp " + Exp);
			EyeColorIntensityAlpha = FMath::EaseIn(0.0f, 1.0f, Alpha, Exp);
		}
		//PrintToScreen("EyeColorIntensityAlpha " + EyeColorIntensityAlpha);
	}

	void ClearEyeColorIntensityAlpha()
	{
		EyeColorIntensityAlpha = 0.0f;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		//MoveComp.DebugDrawBoundingBox();

		if(!bChargeSongOfLife)
			SongOfLifeCharge = FMath::Max(SongOfLifeCharge - DeltaTime, 0.0f);
		else
			SongOfLifeCharge = FMath::Min(SongOfLifeCharge + DeltaTime, SnakeSettings.Hypnosis);
	

		//if(HasControl())
		//	PrintToScreen("Control: " + Game::FirstLocalPlayer.Name);

		const FLinearColor TargetEyeColor = GetActiveEyeColor();
		const bool bUpdateEyeColor = !CurrentEyeColor.Equals(TargetEyeColor);
		CurrentEyeColor = FMath::CInterpTo(CurrentEyeColor, TargetEyeColor, DeltaTime, EyeColorTransitionSpeed);

		if(bUpdateEyeColor)
		{
			HeadMesh.SetColorParameterValueOnMaterialIndex(0, n"EmissiveColor", CurrentEyeColor);
		}

#if TEST
		if(bAlwaysDrawVision)
			DebugDrawVision();
#endif // TEST

		if(!bDebugWeakPoint)
		{
			if(CurrentState == EMurderMicrophoneHeadState::Hypnosis && !IsSnakeInsideCoreRevealRadius() && !bWeakPointRevealed)
			{
				RevealWeakPoint();
			}
			else if(bWeakPointRevealed && (CurrentState != EMurderMicrophoneHeadState::Hypnosis || IsSnakeInsideCoreRevealRadius()))
			{
				HideWeakPoint();
			}
		}

		bWasCoreRevealed = bWeakPointRevealed;

		float LODDistance = 7000.0f;
		float LODDistanceSq = FMath::Square(LODDistance);
		//PrintToScreen("DistanceToClosestPlayerSq " + FMath::Sqrt(DistanceToClosestPlayerSq));

		// Far aways here, let's lower the detail level on the body
		if(DistanceToClosestPlayerSq > LODDistanceSq)
		{
			int OutNumSides = 4;
			float OutCordDetailLevel = 40.0f;
			GetLODDetailLevel(OutNumSides, OutCordDetailLevel);
			BodyComponent.OverrideNumSides(OutNumSides);
			CordDetailLevel = OutCordDetailLevel;
		}
		else
		{
			int OutNumSides = 4;
			float OutCordDetailLevel = 40.0f;
			GetStandardDetailLevel(OutNumSides, OutCordDetailLevel);
			BodyComponent.OverrideNumSides(OutNumSides);
			CordDetailLevel = OutCordDetailLevel;
		}
	}

	private void MakeEyeColorDirty()
	{
		ColorTransition = 0.0f;
	}

	void UpdateSpline(float DeltaTime)
	{
		CalculateSplinePath(DeltaTime);
		UpdateCordOriginLocations();
	}

	UFUNCTION()
	private void Handle_SongOfLifeBegin(FSongOfLifeInfo Info)
	{
		bChargeSongOfLife = true;
	}

	UFUNCTION()
	private void Handle_SongOfLifeEnd(FSongOfLifeInfo Info)
	{
		bChargeSongOfLife = false;
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_CymbalImpact(FCymbalHitInfo HitInfo)
	{
		DestroyMurderMicrophone();
	}

	private void DestroyMurderMicrophone()
	{
		if(!HasControl())
			return;
		
		if(!bWeakPointRevealed)
			return;
			
		if((CurrentHeadState != EMurderMicrophoneHeadState::Hypnosis && !bDebugWeakPoint))
			return;

		if(bIsDestroyed)
			return;

		FHazeDelegateCrumbParams CrumbParams;
		CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_DestroyMurderMicrophone"), CrumbParams);
	}

	UFUNCTION()
	private void Crumb_DestroyMurderMicrophone(FHazeDelegateCrumbData CrumbData)
	{
		Internal_DestroyMurderMicrophone();
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_CymbalImpact_Head(FCymbalHitInfo HitInfo)
	{
		Flinch();
	}

	void AddEyeColor(const FLinearColor& InEyeColor, UObject InInstigator, int InPriority)
	{
		for(const FMurderMicrophoneEyeColorInfo& EyeColorInfo : EyeColorList)
		{
			if(InInstigator == EyeColorInfo.Instigator)
			{
				devEnsure(false, "This Instigator for MurderMicrophone eye color already exists.");
				return;
			}
		}

		FMurderMicrophoneEyeColorInfo NewEyeColorInfo;
		NewEyeColorInfo.Instigator = InInstigator;
		NewEyeColorInfo.TargetColor = InEyeColor;
		NewEyeColorInfo.Priority = InPriority;

		EyeColorList.Add(NewEyeColorInfo);
		MakeEyeColorDirty();
	}

	void SetOrAddEyeColor(const FLinearColor& InEyeColor, UObject InInstigator, int InPriority = 0)
	{
		MakeEyeColorDirty();
		for(FMurderMicrophoneEyeColorInfo& EyeColorInfo : EyeColorList)
		{
			if(InInstigator == EyeColorInfo.Instigator)
			{
				EyeColorInfo.TargetColor = InEyeColor;
				return;
			}
		}

		FMurderMicrophoneEyeColorInfo NewEyeColorInfo;
		NewEyeColorInfo.Instigator = InInstigator;
		NewEyeColorInfo.TargetColor = InEyeColor;
		NewEyeColorInfo.Priority = InPriority;

		EyeColorList.Add(NewEyeColorInfo);
	}

	void RemoveEyeColor(UObject InInstigator)
	{
		for(int Index = EyeColorList.Num() - 1; Index >= 0; --Index)
		{
			if(EyeColorList[Index].Instigator == InInstigator)
			{
				EyeColorList.RemoveAt(Index);
			}
		}

		MakeEyeColorDirty();
	}

	private float EyeColorIntensityAlpha = 0.0f;

	protected FLinearColor GetActiveEyeColor() const
	{
		if(EyeColorList.Num() == 0)
		{
			return StandardEyeColor;
		}

		return EyeColorList.Last().TargetColor + (EyeColorList.Last().TargetColor * (EyeColorIntensity * EyeColorIntensityAlpha));
	}

	FLinearColor GetHypnosisEyerColor() const
	{
		if(HypnosisEyeColorCurve != nullptr)
		{
			const float Percent = FMath::Clamp(SongOfLifeCharge / 0.5f, 0.0f, 1.0f);
			return HypnosisEyeColorCurve.GetLinearColorValue(Percent);
		}

		devEnsure(false, "No Color curve has been selected for the hypnosis color.");

		return FLinearColor::White;
	}

	void DebugDestroyMurderMicrophone()
	{
		if(bIsDestroyed)
			return;

		FHazeDelegateCrumbParams CrumbParams;
		CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_DestroyMurderMicrophone"), CrumbParams);
	}

	private void Internal_DestroyMurderMicrophone()
	{
		_TargetPlayer = nullptr;
		TargetingComponent.bIgnorePlayer = true;
		bIsDestroyed = true;
		Niagara::SpawnSystemAtLocation(CoreExplosionFX, MicSpool.WorldLocation, FRotator::ZeroRotator);
		UHazeAkComponent::HazePostEventFireForget(ExplosionEvent, ActorTransform);
		CymbalImpact.Deactivate();
		CymbalImpact.SetWidgetVisible(false);

		MicSpool.SetStaticMesh(DestroyedCoreMesh);

		WeakPoint.SetVisibility(false);
		WeakPointGuard01.SetVisibility(false);
		WeakPointGuard02.SetVisibility(false);
		
		WeakPoint.SetCollisionProfileName(n"NoCollision");
		WeakPointGuard01.SetCollisionProfileName(n"NoCollision");
		WeakPointGuard02.SetCollisionProfileName(n"NoCollision");

		// Now the base is gone, kill the head.

		SetActorTickEnabled(false);
		SongOfLifeComp.Deactivate();
		SongOfLifeComp.DisableSongOfLife();
		//HeadMesh.SetColorParameterValueOnMaterialIndex(0, n"EmissiveColor", FLinearColor::White);
		//HeadMesh.SetAnimClass(nullptr);
		CurrentHeadState = EMurderMicrophoneHeadState::Killed;

		HazeAkComp.HazeStopEvent(CoreAudioEvent.PlayingID);

		BP_OnMurderMicrophoneCoreDestroyed();
		OnMurderMicrophoneCoreDestroyed.Broadcast();
		StasisFieldVFX.Deactivate();
		StasisField.OnPlayerBeginOverlap.Clear();
		StasisField.Deactivate();
	}

	// Should only be called from the DeathCapability
	void Finalize_MurderMicrophoneDestroy()
	{
		BP_OnMurderMicrophoneDestroyed();
		OnMurderMicrophoneDestroyed.Broadcast();
		BodyComponent.SetVisibility(false);
		BodyComponent.Deactivate();
		HeadMesh.SetAnimClass(nullptr);
		HeadMesh.SetVisibility(false);
		//SetActorHiddenInGame(true);
		//SetLifeSpan(5.0f);
		CurrentHeadState = EMurderMicrophoneHeadState::None;
		UHazeAkComponent::HazePostEventFireForget(HeadExplosionEvent, HeadOffset.WorldTransform);

		ForceFeedbackComp.Play();
		CamShakeComp.Play();
	}

	// called when teh head is supposed to explode.
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Murder Microphone Destroyed"))
	void BP_OnMurderMicrophoneDestroyed() {}

	// called when the cymbal hits the core and it explodes.
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Murder Microphone Core Destroyed"))
	void BP_OnMurderMicrophoneCoreDestroyed() {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Reveal Weak Point"))
	void BP_OnRevealWeakPoint() {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Hide Weak Point"))
	void BP_OnHideWeakPoint() {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Exit Hypnosis"))
	void BP_OnExitHypnosis() {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Player Killed by Stasis Field"))
	void BP_OnPlayerKilledByStasisField(AHazePlayerCharacter Player) {}

	void ToggleWeakPoint()
	{
		if(bWeakPointRevealed)
			HideWeakPoint();
		else
			RevealWeakPoint();
	}

	UFUNCTION()
	void DebugToggleWeakPoint()
	{
		bDebugWeakPoint = !bDebugWeakPoint;
		if(bDebugWeakPoint && !bWeakPointRevealed)
			RevealWeakPoint();
	}

	void RevealWeakPoint()
	{
		if(bWeakPointRevealed)
			return;

		bWeakPointRevealed = true;
		OnRevealWeakPoint.Broadcast();
		CymbalImpact.bCanBeTargeted = true;
		BP_OnRevealWeakPoint();
		CoreAudioEvent = HazeAkComp.HazePostEvent(OpenBaseEvent);
		HeadCymbalImpact.SetCymbalImpactEnabled(false);
	}

	void HideWeakPoint()
	{
		if(!bWeakPointRevealed)
			return;

		bWeakPointRevealed = false;
		OnHideWeakPoint.Broadcast();
		CymbalImpact.bCanBeTargeted = false;
		BP_OnHideWeakPoint();
		HazeAkComp.HazePostEvent(CloseBaseEvent);
		HeadCymbalImpact.SetCymbalImpactEnabled(true);
	}

	void SetPendingTargetPlayer(AHazePlayerCharacter InPendingTarget)
	{
		if(!HasControl())
			return;

		if(_PendingTarget == InPendingTarget)
			return;

		if(!CanChangeTarget())
			return;

		_PendingTarget = InPendingTarget;
		ChangeTargetElapsed = 0.5f;
	}

	bool CanChangeTarget() const
	{
		const bool bCanChangeTarget = (CurrentState == EMurderMicrophoneHeadState::Sleeping 
		|| CurrentState == EMurderMicrophoneHeadState::Suspicious
		|| CurrentState == EMurderMicrophoneHeadState::Retreat
		|| CurrentState == EMurderMicrophoneHeadState::Hypnosis
		);

		return bCanChangeTarget;
	}

	void UpdateTarget()
	{
		if(!HasControl())
			return;

		if(_PendingTarget == nullptr)
			return;

		if(!CanChangeTarget())
			return;

		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddObject(n"NewTarget", _PendingTarget);
		CrumbParams.AddNumber(n"ControlState", int(CurrentHeadState));
		CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_SetTarget"), CrumbParams);
	}

	UFUNCTION(NotBlueprintCallable)
	private void Crumb_SetTarget(FHazeDelegateCrumbData CrumbData)
	{
		AHazePlayerCharacter InNewTarget = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"NewTarget"));

		if(HasControl() != InNewTarget.HasControl())
		{
			SetControlSide(InNewTarget);
		}

		EMurderMicrophoneHeadState ControlState = EMurderMicrophoneHeadState(CrumbData.GetNumber(n"ControlState"));
		CurrentHeadState = ControlState;

		_TargetPlayer = InNewTarget;
		_PendingTarget = nullptr;
		MoveComp.ResetRotationVelocity();
	}

	void ClearTarget()
	{
		if(!HasControl())
			return;

		FHazeDelegateCrumbParams CrumbParams;
		CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_ClearTarget"), CrumbParams);
	}

	UFUNCTION(NotBlueprintCallable)
	private void Crumb_ClearTarget(FHazeDelegateCrumbData CrumbData)
	{
		_TargetPlayer = nullptr;
	}

	void SetCurrentState(EMurderMicrophoneHeadState InState) 
	{ 
		if(!HasControl())
			return;

		if(InState == EMurderMicrophoneHeadState::EatingPlayer)
		{
			devEnsure(false, "Always set EatingPlayer state using function StartEatingPlayer.");
			return;
		}

		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddNumber(n"NewState", int(InState));
		CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_SetState"), CrumbParams);
	}

	UFUNCTION(NotBlueprintCallable)
	private void Crumb_SetState(FHazeDelegateCrumbData CrumbData)
	{
		EMurderMicrophoneHeadState NewState = EMurderMicrophoneHeadState(CrumbData.GetNumber(n"NewState"));
		CurrentHeadState = NewState;
	}

	// This should only be called from EatPlayerCapability as it is a bit special, and is synced using a full sync point.
	void Local_SetState(EMurderMicrophoneHeadState NewState)
	{
		CurrentHeadState = NewState;
	}

	UFUNCTION()
	void DebugReviveMurderMicrophone()
	{
		if(!bIsDestroyed)
			return;

		bIsDestroyed = false;
		UnblockCapabilities(CapabilityTags::LevelSpecific, this);
		CymbalImpact.Activate();
		CymbalImpact.SetWidgetVisible(true);
		BodyComponent.SetVisibility(true);
		BodyComponent.Activate();
		MicSpool.SetVisibility(true, true);
		MicSpool.SetStaticMesh(DefaultCoreMesh);
		MicSpool.SetCollisionProfileName(n"BlockAllDynamic");
		WeakPoint.SetCollisionProfileName(n"BlockAllDynamic");
		WeakPointGuard01.SetCollisionProfileName(n"BlockAllDynamic");
		WeakPointGuard02.SetCollisionProfileName(n"BlockAllDynamic");

		// Now the base is gone, kill the head.

		HeadMesh.SetVisibility(true);
		HeadMesh.SetCollisionProfileName(n"BlockOnlyPlayerCharacter");
		SetActorTickEnabled(true);
		SongOfLifeComp.Activate();
		SongOfLifeComp.EnableSongOfLife();
		//HeadMesh.SetColorParameterValueOnMaterialIndex(0, n"EmissiveColor", FLinearColor::White);
		HeadMesh.SetAnimClass(DefaultAnimationClass);
		CurrentHeadState = EMurderMicrophoneHeadState::Sleeping;

		HeadOffset.SetWorldLocation(_HeadStartLocation);
		HeadOffset.SetWorldRotation(_HeadStartRotation);
		HeadMesh.AttachToComponent(HeadOffset);
	}

	private void InitSplinePath()
	{
		const FVector Origin = SnakeCordLocation;
		const FVector Destination = CordExitWorldLocation;
		QuarticBezierCurve.Construct(Origin, SnakeHeadControlPoint, SplineControlPointBottom, SplineControlPointTop, Destination);
		NumSplinePointsCurrent = GetNumSplinePoints() + NumSplinePointsOffset;
		SplinePath.SetNumZeroed(NumSplinePointsCurrent);

		SplinePath[0] = SnakeHeadCordLocation;
		SplinePath[1] = SnakeCordLocation;
		int Index = 1;

		for(int Num = NumSplinePointsCurrent - NumSplinePointsOffset; Index < Num; ++Index)
		{
			float Alpha = FMath::Min(float(Index) / float(Num), 1.0f);
			FVector SplineLoc = QuarticBezierCurve.GetLocation(Alpha);
			SplinePath[Index+1] = SplineLoc;
		}

		Index++;
		SplinePath[Index] = Destination;
		const FVector InsideLoc = CordInsideWorldLocation;
		for(; Index < NumSplinePointsCurrent; ++Index)
		{
			SplinePath[Index] = InsideLoc;
		}
	}

	void CalculateSplinePath(float DeltaTime)
	{
		FVector Destination = CordExitWorldLocation;
		FVector Origin = SnakeCordLocation;
		QuarticBezierCurve.Construct(Origin, SnakeHeadControlPoint, SplineControlPointBottom, SplineControlPointTop, Destination);
		//System::DrawDebugSphere(Origin, 100.0f, 12, FLinearColor::Red);
		int NumPoints = GetNumSplinePoints();

		int OldNumPoints = SplinePath.Num();

		// Increase the requierd number of points if required
		while((NumPoints + 2) >= (NumSplinePointsCurrent - 2))
		{
			NumSplinePointsCurrent += NumSplinePointsOffset;
			SplinePath.SetNum(NumSplinePointsCurrent);
		}

		if(OldNumPoints != SplinePath.Num())
		{
			for(int Index = OldNumPoints, Num = SplinePath.Num(); Index < Num; ++Index)
				SplinePath[Index] = Destination;
		}

		// Decrease our points if we can
		while(NumPoints < (NumSplinePointsCurrent - 15))
		{
			NumSplinePointsCurrent -= NumSplinePointsOffset;
			SplinePath.SetNum(NumSplinePointsCurrent);
		}

		FVector LastPosition = CordInsideWorldLocation;
		float CordDistanceSq = 0.0f;
		bool bHasChangedDetail = CordDetailLevel != LastCordDetailLevel;

		const float InterpSpeed = bHasChangedDetail ? 800.0f : 8.0f;
		
		int Index = 1;
		
		float Alpha = 0.0f;
		float InterpSpeedScalar = 0.0f;
		FVector SplineLoc;
		
		Index = 1;
		for(; Index < NumPoints; ++Index)
		{
			Alpha = FMath::Min(float(Index) / float(NumPoints), 1.0f);
			InterpSpeedScalar = float(NumPoints) / float(Index);
			SplineLoc = QuarticBezierCurve.GetLocation(Alpha);
			SplinePath[Index+1] = FMath::VInterpTo(SplinePath[Index+1], SplineLoc, DeltaTime, InterpSpeed * InterpSpeedScalar);
		}

		SplinePath[Index+1] = Destination;
		Index++;
		SplinePath[Index+1] = LastPosition;
		const FVector CordInside = CordInsideWorldLocation;
		Index++;
		SplinePath[Index] = FMath::VInterpTo(SplinePath[Index], CordInside, DeltaTime, InterpSpeed);
		Index++;

		for(int Num = SplinePath.Num(); Index < Num; ++Index)
		{
			SplinePath[Index] = CordInside;
		}

		LastCordDetailLevel = CordDetailLevel;
	}

	UFUNCTION()
	void TestFlinch(bool bValue)
	{
		bIsFlinching = bValue;
	}

	float GetCordLengthCurrent() const property
	{
		return QuarticBezierCurve.CurveLength;
	}

	int CalculateNumSplinePointsTotal() const
	{
		return FMath::CeilToInt(CordMaxLength / CordDetailLevel) + 2;	// +2 because we want an extra location for the head root and one for inside the base.
	}

	float GetMaxLength() const property
	{
		return TargetingComponent.ChaseRange * 1.15f;
	}

	float CalculateNumSplinePoints() const
	{
		const float SegmentLength = QuarticBezierCurve.CurveLength;
		return float(FMath::CeilToInt(SegmentLength / CordDetailLevel) + 2);	// +2 because final point on head is inside, same for final point inside base.
	}

	float CalculateNumSplinePoints(float SegmentLength) const
	{
		return FMath::CeilToInt(SegmentLength / CordDetailLevel) + 2;	// +2 because final point on head is inside, same for final point inside base.
	}

	FVector GetSplineControlPointTop() const property
	{
		FVector ControlPoint = ActorTransform.TransformPosition(Local_CordControlPointTop);
		ControlPoint += CordBottomOffset;
		return ControlPoint;
	}

	FVector GetSplineControlPointBottom() const property
	{
		FVector ControlPoint = ActorTransform.TransformPosition(Local_CordControlPointBottom);
		ControlPoint += ActorRightVector * ControlPointTopOffset;
		ControlPoint += WiggleOffset;
		return ControlPoint;
	}

	FVector GetSnakeHeadControlPoint() const property
	{
		FVector ControlPoint = HeadMesh.GetSocketLocation(n"Tongue1") + (HeadMesh.ForwardVector * -1.0f) * HeadControlPointLength * 1.5f;
		//ControlPoint += HeadMesh.ForwardVector * GetPulseValue(0.2f) * 0.4f;
		return ControlPoint;
	}
	
	// Where to attach and hide teh cord inside the head.
	FVector GetSnakeHeadCordLocation() const property
	{
		return HeadMesh.GetSocketLocation(n"Base");
	}

	FVector GetSnakeHeadCenterLocation() const property
	{
		return HeadMesh.GetSocketLocation(n"Tongue2");
	}

	FVector GetSnakeCordLocation() const property
	{
		return HeadMesh.GetSocketLocation(n"CordExit");
	}

	FVector GetSnakeHeadLocation() const property
	{
		return HeadOffset.WorldLocation;
	}

	FVector GetSnakeCordExitLocation() const property
	{
		return HeadMesh.GetSocketLocation(n"CordExit");
	}

	float GetPulseValue(float Scalar) const
	{
		const float Value = (FMath::MakePulsatingValue(System::GameTimeInSeconds, Scalar) * 2.0f) - 1.0f;
		return Value;
	}

	bool HasReachedTargetLocation() const
	{
		const float DistanceToTargetLocationSq = MoveComp.TargetLocation.DistSquared(SnakeHeadLocation);
		const bool bHasReachedTargetLocation = (DistanceToTargetLocationSq - FMath::Square((SnakeSettings.SlowdownDistance.Y))) <= 0.0f;
		return bHasReachedTargetLocation;
	}

	bool IsKilled() const
	{
		return CurrentHeadState == EMurderMicrophoneHeadState::Killed;
	}

	// Returns true if snake is not in hypnosis but has enough song of life charge to enter.
	bool ShouldEnterHypnosis() const
	{
		const bool bIsInHypnosis = IsInHypnosis();
		const bool bReadyForHypnosis = SongOfLifeCharge >= SnakeSettings.Hypnosis;
		return !bIsInHypnosis && bReadyForHypnosis;
	}

	void DebugDrawSplinePath() const
	{
		if(SplinePath.Num() < 3)
			return;

		FVector PrevLoc = SplinePath[0];

		for(int Index = 1, Num = SplinePath.Num(); Index < Num; ++Index)
		{
			FVector CurrLoc = SplinePath[Index];
			System::DrawDebugLine(PrevLoc, CurrLoc, FLinearColor::Red, 0, 5.0f);
			System::DrawDebugSphere(CurrLoc, 150.0f, 12, FLinearColor::Blue);
			PrevLoc = CurrLoc;
		}
	}

	bool IsTargetBelowSnake() const
	{
		if(_TargetPlayer == nullptr)
			return false;

		const float UpDir = DirectionToTarget.DotProduct(FVector::UpVector);
		const bool bIsBelow = UpDir < 0.0f;
		return bIsBelow;
	}

	void Flinch()
	{
		if(bIsFlinching)
			return;

		bIsFlinching = true;
		System::SetTimer(this, n"Handle_FlinchStop", 0.83f, false);
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_FlinchStop()
	{
		bIsFlinching = false;
	}

	void DebugDrawVision()
	{
		TargetingComponent.DebugDrawVision();
		System::DrawDebugSphere(ActorLocation, CoreRevealRange, 12, FLinearColor::Green, 0, 6);
	}

	void StartEatingPlayer(AHazePlayerCharacter InTargetToEat)
	{
		if(!HasControl())
			return;		
	
		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddObject(n"TargetToEat", InTargetToEat);
		CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_StartEatingPlayer"), CrumbParams);
	}

	bool IsIgnoringPlayer() const
	{
		return TargetingComponent.bIgnorePlayer;
	}

	FVector GetDirectionToTarget() const property
	{
		if(_TargetPlayer == nullptr)
			return HeadOffset.ForwardVector;

		const FVector Dir = (_TargetPlayer.ActorCenterLocation - HeadOffset.WorldLocation).GetSafeNormal();
		return Dir;
	}

	UFUNCTION()
	void SetIgnorePlayer(bool bValue)
	{
		if(!HasControl())
			return;

		const bool bIsIgnoringPlayer = IsIgnoringPlayer();

		if(bIsIgnoringPlayer && !bValue)
		{
			TargetingComponent.SetIgnorePlayer(false);
		}
		else if(bValue && !bIsIgnoringPlayer)
		{
			TargetingComponent.SetIgnorePlayer(true);
			ClearTarget();
		}
	}

	void ToggleIgnorePlayer()
	{
		if(IsIgnoringPlayer())
			SetIgnorePlayer(false);
		else
			SetIgnorePlayer(true);
	}

	UFUNCTION(NotBlueprintCallable)
	private void Crumb_StartEatingPlayer(FHazeDelegateCrumbData CrumbData)
	{
		AHazePlayerCharacter NewTargetToEat = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"TargetToEat"));
		TargetToEat = NewTargetToEat;
		CurrentHeadState = EMurderMicrophoneHeadState::EatingPlayer;
	}

	float GetDistanceToBase2D() const property
	{
		return HeadOffset.WorldLocation.Dist2D(ActorLocation);
	}

	float GetHeadToCoreDistanceSq() const property { return HeadOffset.WorldLocation.DistSquared2D(ActorLocation); }

	bool IsSnakeInsideChaseRadius() const
	{
		return IsLocationInsideChaseRange(SnakeHeadCenterLocation);
	}

	bool IsSnakeInsideAggressiveRadius() const
	{
		return IsLocationInsideAggressiveRange(SnakeHeadCenterLocation);
	}

	bool IsSnakeInsideCoreRevealRadius() const
	{
		const bool bIsInsideCoreRevealRange = HeadToCoreDistanceSq < CoreRevealRangeSq;
		return bIsInsideCoreRevealRange;
	}

	bool IsLocationInsideChaseRange(FVector Location) const
	{
		const float DistanceToCoreSq = TargetingComponent.bTargetOnly2D ? Location.DistSquared2D(ActorLocation) : Location.DistSquared(ActorLocation);
		const bool bIsInsideChaseRange = DistanceToCoreSq < TargetingComponent.ChaseRangeSq;
		
		if(MoveComp.bConstrainWithinBoundingBox)
		{
			return MoveComp.IsWithinBoundingBox(Location) && bIsInsideChaseRange;
		}

		return bIsInsideChaseRange;
	}

	bool IsLocationInsideAggressiveRange(FVector Location) const
	{
		const float DistanceToCoreSq = TargetingComponent.bTargetOnly2D ? Location.DistSquared2D(ActorLocation) : Location.DistSquared(ActorLocation);
		const bool bIsInsideAggressiveRange = DistanceToCoreSq < TargetingComponent.AggressiveRangeSq;
		
		if(MoveComp.bConstrainWithinBoundingBox)
		{
			return MoveComp.IsWithinBoundingBox(Location) && bIsInsideAggressiveRange;
		}

		return bIsInsideAggressiveRange;
	}

	void UpdateCordOriginLocations()
	{
		SplinePath[0] = SnakeHeadCordLocation;
		SplinePath[1] = SnakeCordLocation;
		UpdateSplinePoints();
	}

	private void UpdateSplinePoints()
	{
		BodyComponent.SetParticlesFromLocations(SplinePath);
	}

	UFUNCTION()
	void DebugSwallow()
	{
		bSwallowPlayer = true;
	}

	FVector GetHeadUpVector() const property
	{
		const FTransform HeadSocketTransform = HeadMesh.GetSocketTransform(n"Base");
		return HeadSocketTransform.Rotation.UpVector;
	}

	UFUNCTION()
	void PlayMayBark()
	{
		PlayFoghornVOBankEvent(FoghornDataAsset, n"FoghornDBMusicBackstageSilentRoomSnakeKill");
	}

	void PlayOnEatenBark(AHazePlayerCharacter Player)
	{
		FName BarkId = Player == Game::GetCody() ? n"FoghornDBMusicBackstageSilentRoomSnakeDeathEffortCody" : n"FoghornDBMusicBackstageSilentRoomSnakeDeathEffortMay";
		PlayFoghornVOBankEvent(FoghornDataAsset, BarkId);
	}

	float GetDistanceToClosestPlayerSq() const property
	{
		const float CodyDistSq = Game::Cody.ActorLocation.DistSquared2D(SnakeHeadLocation);
		const float MayDistSq = Game::May.ActorLocation.DistSquared2D(SnakeHeadLocation);

		if(CodyDistSq > MayDistSq)
			return MayDistSq;

		return CodyDistSq;
	}

	void GetHighDetailLevel(int& OutNumSides, float& OutCordDetailLevel) const
	{
		OutNumSides = 7;
		OutCordDetailLevel = 30.0f;
	}

	void GetMediumDetailLevel(int& OutNumSides, float& OutCordDetailLevel) const
	{
		OutNumSides = 6;
		OutCordDetailLevel = 40.0f;
	}

	void GetLowDetailLevel(int& OutNumSides, float& OutCordDetailLevel) const
	{
		OutNumSides = 5;
		OutCordDetailLevel = 45.0f;
	}

	void GetLODHighDetailLevel(int& OutNumSides, float& OutCordDetailLevel) const
	{
		OutNumSides = 4;
		OutCordDetailLevel = 250.0f;
	}

	void GetLODMediumDetailLevel(int& OutNumSides, float& OutCordDetailLevel) const
	{
		OutNumSides = 3;
		OutCordDetailLevel = 300.0f;
	}

	void GetLODLowDetailLevel(int& OutNumSides, float& OutCordDetailLevel) const
	{
		OutNumSides = 3;
		OutCordDetailLevel = 350.0f;
	}

	void GetLODDetailLevel(int& OutNumSides, float& OutCordDetailLevel) const
	{
		if(DetailSettings == EMurderMicrophoneDetailLevel::Default)
		{
			if(Game::DetailModeHigh)
				GetLODHighDetailLevel(OutNumSides, OutCordDetailLevel);
			else if(Game::DetailModeMedium)
				GetLODMediumDetailLevel(OutNumSides, OutCordDetailLevel);
			else if(Game::DetailModeLow)
				GetLODLowDetailLevel(OutNumSides, OutCordDetailLevel);
		}
		else
		{
			if(DetailSettings == EMurderMicrophoneDetailLevel::High)
				GetLODHighDetailLevel(OutNumSides, OutCordDetailLevel);
			else if(DetailSettings == EMurderMicrophoneDetailLevel::Medium)
				GetLODMediumDetailLevel(OutNumSides, OutCordDetailLevel);
			else if(DetailSettings == EMurderMicrophoneDetailLevel::Low)
				GetLODLowDetailLevel(OutNumSides, OutCordDetailLevel);
		}
	}

	void GetStandardDetailLevel(int& OutNumSides, float& OutCordDetailLevel) const
	{
		if(DetailSettings == EMurderMicrophoneDetailLevel::Default)
		{
			if(Game::DetailModeHigh)
				GetHighDetailLevel(OutNumSides, OutCordDetailLevel);
			else if(Game::DetailModeMedium)
				GetMediumDetailLevel(OutNumSides, OutCordDetailLevel);
			else if(Game::DetailModeLow)
				GetLowDetailLevel(OutNumSides, OutCordDetailLevel);
		}
		else
		{
			if(DetailSettings == EMurderMicrophoneDetailLevel::High)
				GetHighDetailLevel(OutNumSides, OutCordDetailLevel);
			else if(DetailSettings == EMurderMicrophoneDetailLevel::Medium)
				GetMediumDetailLevel(OutNumSides, OutCordDetailLevel);
			else if(DetailSettings == EMurderMicrophoneDetailLevel::Low)
				GetLowDetailLevel(OutNumSides, OutCordDetailLevel);
		}
	}
}
