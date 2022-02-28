import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobTrigger;

class ABasementFallingObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ObjectRoot;

	UPROPERTY(DefaultComponent, Attach = ObjectRoot)
	UStaticMeshComponent ObjectMesh;

	UPROPERTY()
	AParentBlobTrigger Trigger;
	
	UPROPERTY()
	bool bPreviewEndTransform = false;

	UPROPERTY(meta = (MakeEditWidget))
	FTransform EndTransform;

	UPROPERTY()
	float PlayRate = 0.5f;

	UPROPERTY()
	float FallDelay = 0.f;

	UPROPERTY()
	FHazeTimeLike MoveObjectTimeLike;

	UPROPERTY()
	UNiagaraSystem ImpactEffect;

	UPROPERTY()
	FRotator RotationOffset = FRotator(360.f, 360.f, -720.f);

	bool bFallen = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewEndTransform)
			ObjectRoot.SetRelativeTransform(EndTransform);
		else
			ObjectRoot.SetRelativeTransform(FTransform::Identity);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveObjectTimeLike.SetPlayRate(PlayRate);
		MoveObjectTimeLike.BindUpdate(this, n"UpdateMoveObject");
		MoveObjectTimeLike.BindFinished(this, n"FinishMoveObject");

		if (Trigger != nullptr)
			Trigger.OnActorEnter.AddUFunction(this, n"PlayersEnteredTrigger");
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayersEnteredTrigger(AHazeActor Actor)
	{
		Trigger.OnActorEnter.Unbind(this, n"PlayersEnteredTrigger");
		StartFalling();
	}

	UFUNCTION()
	void StartFalling()
	{
		if (bFallen)
			return;

		bFallen = true;

		if (FallDelay == 0.f)
			TriggerFall();
		else
			System::SetTimer(this, n"TriggerFall", FallDelay, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void TriggerFall()
	{
		ObjectRoot.SetRelativeTransform(FTransform::Identity);
		MoveObjectTimeLike.PlayFromStart();
		SetActorHiddenInGame(false);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateMoveObject(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(FVector::ZeroVector, EndTransform.Location, CurValue);

		float RotAlpha = FMath::Clamp(CurValue + 0.05f, 0.f, 1.f);
		float Pitch = FMath::Lerp(0.f, RotationOffset.Pitch, RotAlpha);
		float Yaw = FMath::Lerp(0.f, RotationOffset.Yaw, RotAlpha);
		float Roll = FMath::Lerp(0.f, RotationOffset.Roll, RotAlpha);
		FRotator CurRot = FRotator(Pitch, Yaw, Roll);

        ObjectRoot.SetRelativeLocationAndRotation(CurLoc, CurRot);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishMoveObject()
	{
		if (ImpactEffect != nullptr)
			Niagara::SpawnSystemAtLocation(ImpactEffect, ObjectRoot.WorldLocation);
	}
}