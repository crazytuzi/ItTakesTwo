import Cake.LevelSpecific.Music.Cymbal.CymbalImpactComponent;
import Peanuts.Aiming.AutoAimTarget;
import Cake.LevelSpecific.Music.LevelMechanics.GuitarTuningKeyConnectedActor;

event void FOnCymbalHitTuningKey();

UCLASS(Abstract, HideCategories = "Rendering Debug Collision Replication Input Actor LOD Cooking")
class AGuitarTuningKey : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TuningKeyRoot;

	UPROPERTY(DefaultComponent, Attach = TuningKeyRoot)
	UStaticMeshComponent TuningKeyMesh;

	UPROPERTY(DefaultComponent)
	UCymbalImpactComponent CymbalImpactComp;

	UPROPERTY(DefaultComponent)
	UAutoAimTargetComponent AutoAimComp1;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncedProgress;

	UPROPERTY()
	FOnCymbalHitTuningKey OnCymbalHitTuningKey;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike HitRotationTimeLike;
	default HitRotationTimeLike.bSyncOverNetwork = false;
	default HitRotationTimeLike.bCurveUseNormalizedTime = true;

	UPROPERTY(NotEditable)
	float CurrentProgress = 0.f;

	UPROPERTY(EditDefaultsOnly)
	int NumberOfRotations = 3;

	UPROPERTY()
	TArray<AGuitarTuningKeyConnectedActor> ConnectedActors;

	bool bIsReversing = false;
	float TargetLocalYaw = 0.0f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CymbalImpactComp.OnCymbalHit.AddUFunction(this, n"CymbalHit");

		HitRotationTimeLike.BindUpdate(this, n"UpdateHitRotation");
		HitRotationTimeLike.BindFinished(this, n"FinishHitRotation");

		// Because this uses the cymbal we know it is going to be Cody
		SetControlSide(Game::GetCody());
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateHitRotation(float CurValue)
	{		
		TargetLocalYaw = CurValue * (360.0f * (float(NumberOfRotations)));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishHitRotation()
	{
		if(!bIsReversing)
		{
			ReverseTuningKey();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void CymbalHit(FCymbalHitInfo HitInfo)
	{
		if(!HasControl())
		{
			return;
		}

		if(!HitRotationTimeLike.IsPlaying() || bIsReversing)
		{
			StartTuningKey();
			OnCymbalHitTuningKey.Broadcast();
		}
	}

	void ReverseTuningKey()
	{
		if(bIsReversing)
		{
			return;
		}

		bIsReversing = true;
		HitRotationTimeLike.SetPlayRate(0.2f);
		HitRotationTimeLike.ReverseFromEnd();
	}

	void StartTuningKey()
	{
		bIsReversing = false;
		HitRotationTimeLike.SetPlayRate(1.0f);
		HitRotationTimeLike.Play();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(HasControl())
		{
			for (AGuitarTuningKeyConnectedActor CurActor : ConnectedActors)
			{
				CurActor.UpdateProgress(HitRotationTimeLike.GetValue());
			}

			TuningKeyRoot.SetRelativeRotation(FRotator(0.0f, TargetLocalYaw, 0.0f));
			SyncedProgress.Value = HitRotationTimeLike.GetValue();
		}
		else
		{
			for (AGuitarTuningKeyConnectedActor CurActor : ConnectedActors)
			{
				CurActor.UpdateProgress(SyncedProgress.Value);
			}

			const float LocalYaw = SyncedProgress.Value * (360.0f * (float(NumberOfRotations)));
			TuningKeyRoot.SetRelativeRotation(FRotator(0.0f, LocalYaw, 0.0f));
		}
	}
}
