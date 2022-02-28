import Cake.Environment.BreakableComponent;
import Cake.LevelSpecific.SnowGlobe.Mountain.TriggerableFX;
import Peanuts.Outlines.Stencil;

struct AttachedTriggerableEffect
{
	UPROPERTY()
	ATriggerableFX Effect;

	UPROPERTY()
	FName JointName;
}

UCLASS(hidecategories="Physics Collision Rendering Physics Activation Cooking Replication Input Actor HLOD Mobile AssetUserData")
class AReversableBreakableActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent StaticMeshComponent;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase SkeletalMeshComponent;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 15000.f;

	UPROPERTY(Category="General")
	float StartTime = 0;

	UPROPERTY(Category="General")
	TArray<AttachedTriggerableEffect> AttachedEffects;
	
	// If checked, time will change on tick as a test.
	UPROPERTY(Category="General")
	bool TestTime = false;

	UPROPERTY(Category="Explodable")
	bool StaticMeshCastShadows = true;

	UPROPERTY(Category="Explodable", Meta = (MakeEditWidget))
	FTransform StaticMeshTransform;

	UPROPERTY(Category="Explodable")
	UStaticMesh StaticMesh;

	UPROPERTY(Category="Explodable")
	TArray<UMaterialInterface> MaterialOverrides;

	UPROPERTY(Category="Explodable", Meta = (MakeEditWidget))
	FVector BreakableHitLocation = FVector(-50, 0, 200);

	UPROPERTY(Category="Explodable")
	FVector BreakableHitDirectionalForce = 1.0f;

	UPROPERTY(Category="Explodable")
	float BreakableHitScatterForce = 5.0f;


	UPROPERTY(Category="Explodable")
	bool SkeletalMeshCastShadows = true;

	UPROPERTY(Category="BakedPhysics")
	FRuntimeFloatCurve BakedPhysicsTimeRemapCurve;

	UPROPERTY(Category="BakedPhysics", Meta = (MakeEditWidget))
	FTransform SkeletalMeshTransform;

	UPROPERTY(Category="BakedPhysics")
	USkeletalMesh SkeletalMesh;

    UPROPERTY(Category="BakedPhysics")
    UAnimSequence SkeletalMeshAnimation;

	UPROPERTY(Category="Linear Trajectory")
	bool bLinearTrajectory = false;

	UPROPERTY(Category="Linear Trajectory", Meta = (EditCondition = "bLinearTrajectory", EditConditionHides))
	float TrajectoryDuration = 0.f;

	UPROPERTY(Category="Linear Trajectory", Meta = (EditCondition = "bLinearTrajectory", EditConditionHides))
	FVector TrajectoryEndPosition;

	private float PreviousTime = MIN_flt;
	private bool bIsAnimating = false;
	private int LastScrubFrame = -1;
	private TArray<ATriggerableFX> ActiveEffects;
	
	UFUNCTION()
	void SetTimeWarp(ETimeWarStencilState State)
	{
		SetTimewarpNew(SkeletalMeshComponent, State);
		SetTimewarpNew(StaticMeshComponent, State);
		
		if(State == ETimeWarStencilState::Active)
		{
			for(ATriggerableFX a : GetAllTriggerableEffects(this))
			{
				a.NiagaraComponent.SetNiagaraVariableFloat("User.Frozen", 0.0f);
			}
		}
		else
		{
			for(ATriggerableFX a : GetAllTriggerableEffects(this))
			{
				a.NiagaraComponent.SetNiagaraVariableFloat("User.Frozen", 1.0f);
			}
		}
	}

    UFUNCTION(BlueprintPure, Category="BakedPhysics")
	float GetCurrentTime()
	{
		return PreviousTime;
	}

    UFUNCTION(Category="BakedPhysics")
	void SetTime(float Time)
	{
		if (Time == PreviousTime)
			return;
		PreviousTime = Time;

		// Is this abuse?
		if(SkeletalMeshComponent.SkeletalMesh != nullptr && SkeletalMeshAnimation != nullptr)
		{
			float BakedPhysicsTime = BakedPhysicsTimeRemapCurve.GetFloatValue(Time);
			SkeletalMeshComponent.AnimationData.SavedPosition = BakedPhysicsTime;
			
			float ClampedBakedPhysicsTime = FMath::Clamp(BakedPhysicsTime, 0.0f, SkeletalMeshAnimation.GetPlayLength()-0.1f);
			FHazePlaySlotAnimationParams a = FHazePlaySlotAnimationParams();
			a.Animation = SkeletalMeshAnimation;
			a.bLoop = false;
			a.BlendTime = 0;
			a.StartTime = ClampedBakedPhysicsTime;
			a.PlayRate = 0.0001f;
			FHazeAnimationDelegate OnBlendingIn;
			FHazeAnimationDelegate OnBlendingOut;
			SkeletalMeshComponent.PlaySlotAnimation(OnBlendingIn, OnBlendingOut, a);
			SkeletalMeshComponent.SetScalarParameterValueOnMaterials(n"ReversableTime", Time);

			LastScrubFrame = GFrameNumber;
			if (!bIsAnimating)
			{
				bIsAnimating = true;
				SetActorTickEnabled(true);
				SkeletalMeshComponent.SetComponentTickEnabled(true);
			}
		}

		if (bLinearTrajectory && TrajectoryDuration > 0.f)
		{
			float TrajectoryAlpha = Math::Saturate(Time / TrajectoryDuration);
			SkeletalMeshComponent.SetRelativeLocation(
				FMath::Lerp(FVector::ZeroVector, TrajectoryEndPosition, TrajectoryAlpha)
			);
		}

		if(StaticMeshComponent.StaticMesh != nullptr)
		{
			SetExplodableParametersFromStruct(0, StaticMeshComponent, BreakableHitLocation, BreakableHitDirectionalForce, BreakableHitScatterForce, Time);
		}

		for (ATriggerableFX a : ActiveEffects)
			a.SetReversableEffectTime(Time);
	}
	
	FVector MoveTowards(FVector Current, FVector Target, float StepSize)
    {
		FVector Delta = Target - Current;
		float Distance = Delta.Size();
		float ClampedDistance = FMath::Min(Distance, StepSize);
		FVector Direction = Delta / Distance;
        return Current + Direction * ClampedDistance;
    }
	
	void SetExplodableParametersFromStruct(int MaterialIndex, UStaticMeshComponent Mesh, FVector LocalHitLocation, FVector LocalHitDirectionalForce, float Scatterforce, float Time)
	{
		FBreakableHitData HitData;
		HitData.HitLocation = GetActorTransform().TransformPosition(LocalHitLocation);
		HitData.DirectionalForce = GetActorTransform().TransformVector(LocalHitDirectionalForce);
		HitData.ScatterForce = Scatterforce;

		bool GroundCollision = true;
		float ChunkFadeTime = 1.0f;
		float ChunkRotaitonMultiplier = 1.0f;
		float ChunkMass = 1.0f;
		bool IsOnWater = false;


		// If the provided HitLocation is outside of the objects radius we move it to the surface of the radius.
		FVector Origin;
		FVector Bounds;
		float Radius = 0;
		System::GetComponentBounds(Mesh, Origin, Bounds, Radius);
		// Number to scale force with so that the input 1 feels like a good default.
		float StrengthConvenienceMultiplier = 10000.0f;
		
		StrengthConvenienceMultiplier /= ChunkMass;

		StaticMeshComponent.SetColorParameterValueOnMaterialIndex(MaterialIndex, n"HitLocation", FLinearColor(HitData.HitLocation.X, HitData.HitLocation.Y, HitData.HitLocation.Z, 0.0f));
		StaticMeshComponent.SetColorParameterValueOnMaterialIndex(MaterialIndex, n"DirectionalForce", FLinearColor(HitData.DirectionalForce.X, HitData.DirectionalForce.Y, HitData.DirectionalForce.Z, 0.0f) * StrengthConvenienceMultiplier);
		
		StaticMeshComponent.SetScalarParameterValueOnMaterialIndex(MaterialIndex, n"Radius", Radius * 2.0f);
		StaticMeshComponent.SetScalarParameterValueOnMaterialIndex(MaterialIndex, n"ScatterForce", HitData.ScatterForce * StrengthConvenienceMultiplier);
		StaticMeshComponent.SetScalarParameterValueOnMaterialIndex(MaterialIndex, n"PlaneHeight", GroundCollision ? Mesh.GetWorldLocation().Z : -292999.0f);
		StaticMeshComponent.SetScalarParameterValueOnMaterialIndex(MaterialIndex, n"IsOnWater", IsOnWater ? 1.0f : 0.0f);
		StaticMeshComponent.SetScalarParameterValueOnMaterialIndex(MaterialIndex, n"RotationForce", ChunkRotaitonMultiplier);
		StaticMeshComponent.SetScalarParameterValueOnMaterialIndex(MaterialIndex, n"FadeTime", ChunkFadeTime * 0.25f);
		StaticMeshComponent.SetScalarParameterValueOnMaterialIndex(MaterialIndex, n"Time", Time);
		StaticMeshComponent.SetScalarParameterValueOnMaterialIndex(MaterialIndex, n"ReversableTime", Time);
	}

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(TestTime)
		{
			SetTime((1.0f - FMath::Abs(FMath::Sin(Time::GetGameTimeSeconds())))*10.0f);
		}

		if (bIsAnimating)
		{
			if ((GFrameNumber - LastScrubFrame) > 2)
			{
				if(SkeletalMeshComponent.SkeletalMesh != nullptr && SkeletalMeshAnimation != nullptr)
					SkeletalMeshComponent.SetComponentTickEnabled(false);
				bIsAnimating = false;
			}
		}

		if (!TestTime && !bIsAnimating)
		{
			SetActorTickEnabled(false);
		}
	}
	
    UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(ATriggerableFX a : GetAllTriggerableEffects(this))
		{
			a.NiagaraComponent.Activate();
			ActiveEffects.Add(a);
		}

		if(SkeletalMeshComponent != nullptr)
		{
			for(AttachedTriggerableEffect a : AttachedEffects)
			{
				a.Effect.NiagaraComponent.Activate();
				if (SkeletalMeshAnimation != nullptr)
					a.Effect.AttachToComponent(SkeletalMeshComponent, a.JointName);
				else
					a.Effect.AttachToComponent(SkeletalMeshComponent);
				a.Effect.NiagaraComponent.bUseAttachParentBound = true;
			}
		}

		SetTime(StartTime);
	}

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		SkeletalMeshComponent.SetSkeletalMesh(SkeletalMesh);
		SkeletalMeshComponent.SetRelativeTransform(SkeletalMeshTransform);
		SkeletalMeshComponent.SetVisibility(true);
		SkeletalMeshComponent.SetHiddenInGame(false);
		SkeletalMeshComponent.CastShadow = SkeletalMeshCastShadows;
		if(SkeletalMesh == nullptr)
			SkeletalMeshComponent.SetVisibility(false);
		else if (SkeletalMeshAnimation == nullptr)
			SkeletalMeshComponent.SetHiddenInGame(true);
		StaticMeshComponent.SetStaticMesh(StaticMesh);
		StaticMeshComponent.SetRelativeTransform(StaticMeshTransform);
		StaticMeshComponent.CastShadow = StaticMeshCastShadows;

		for (int i = 0; i < MaterialOverrides.Num(); i++)
		{
			StaticMeshComponent.SetMaterial(i, MaterialOverrides[i]);
		}

		SetTime(StartTime);
		SkeletalMeshComponent.AnimationData.AnimToPlay = SkeletalMeshAnimation;
    }
}