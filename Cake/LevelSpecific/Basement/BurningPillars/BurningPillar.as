import Cake.Environment.HazeSphere;
import Peanuts.Triggers.ActorTrigger;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Cake.LevelSpecific.Basement.BurningPillars.FireRespawnTunnel;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;

UCLASS(Abstract)
class ABurningPillar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UStaticMeshComponent PillarMesh;

	UPROPERTY(DefaultComponent, Attach = PillarMesh)
	UNiagaraComponent FireEffect;

	UPROPERTY(DefaultComponent, Attach = PillarMesh)
	UNiagaraComponent SmokeEffect;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UHazeSphereComponent HazeSphereComp;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface PreviewMaterial;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike SmolderTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike SinkTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike FireTimeLike;

	UMaterialInstanceDynamic MaterialInstance;

	UPROPERTY()
	UStaticMesh MeshToUse;

	UPROPERTY()
	float SmolderDelay = 0.f;

	UPROPERTY()
	float SinkDelay = 0.f;

	UPROPERTY()
	float FireDelay = 1.f;

	UPROPERTY()
	float SinkSpeed = 1.f;

	UPROPERTY(NotEditable)
	float SmolderShakiness;

	float SmolderTime = 0.f;
	float SinkDistance = 0.f;
	float ShakeTime = 0.f;

	UPROPERTY(meta = (MakeEditWidget))
	FTransform SinkTransform = FTransform(FVector(0.f, 0.f, -100.f));

	UPROPERTY()
	TArray<AActorTrigger> Triggers;

	FTimerHandle SmolderTimerHandle;
	FTimerHandle SinkTimerHandle;
	FTimerHandle FireTimerHandle;

	bool bBurned = false;

	bool bPlayersOnPillar = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		PillarMesh.SetStaticMesh(MeshToUse);

		SinkDelay = FMath::Max(SmolderDelay, SinkDelay);
		FireDelay = FMath::Max(SmolderDelay + 1.f, FireDelay);

		if (SinkTransform.Location.Size() != 0 || SinkTransform.Rotation.Size() != 0)
		{
			UStaticMeshComponent PreviewMeshComp = UStaticMeshComponent::Create(this);
			PreviewMeshComp.SetRelativeTransform(SinkTransform);
			PreviewMeshComp.SetStaticMesh(MeshToUse);
			PreviewMeshComp.SetMaterial(0, PreviewMaterial);
			PreviewMeshComp.SetHiddenInGame(true);
		}

		HazeSphereComp.ConstructionScript_Hack();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SmolderTimeLike.BindUpdate(this, n"UpdateSmolder");
		SinkTimeLike.BindUpdate(this, n"UpdateSink");
		FireTimeLike.BindUpdate(this, n"UpdateFire");
		FireTimeLike.BindFinished(this, n"FinishFire");

		SmolderTime = FireDelay - SmolderDelay;
		SinkDistance = SinkTransform.Location.Size();

		MaterialInstance = Material::CreateDynamicMaterialInstance(PillarMesh.GetMaterial(0));
		PillarMesh.SetMaterial(0, MaterialInstance);
		HazeSphereComp.SetOpacityValue(0.f);

		for (AActorTrigger CurTrigger : Triggers)
		{
			CurTrigger.OnActorEnter.AddUFunction(this, n"PlayersEnteredTrigger");
		}

		FActorImpactedDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"PlayersOnPillar");
		BindOnDownImpacted(this, ImpactDelegate);

		FActorNoLongerImpactingDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"PlayersLeftPillar");
		BindOnDownImpactEnded(this, NoImpactDelegate);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayersOnPillar(AHazeActor Actor, FHitResult Hit)
	{
		AParentBlob ParentBlob = Cast<AParentBlob>(Actor);
		if (ParentBlob == nullptr)
			return;

		bPlayersOnPillar = true;
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayersLeftPillar(AHazeActor Actor)
	{
		AParentBlob ParentBlob = Cast<AParentBlob>(Actor);
		if (ParentBlob == nullptr)
			return;

		bPlayersOnPillar = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (SmolderShakiness == 0)
			return;

		ShakeTime += DeltaTime;

		float ShakeMultiplier = ShakeTime * 30.f;
		float XValue = FMath::Sin(ShakeMultiplier * 1.123f) * (SmolderShakiness * 3);
		float YValue = FMath::Sin(ShakeMultiplier * 0.962f) * (SmolderShakiness * 3);
		float YawValue = FMath::Sin(ShakeMultiplier * 0.581f) * (SmolderShakiness * 2);

		FVector PillarLoc = FVector(XValue, YValue, 0.f);
		FRotator PillarRot = FRotator(0.f, YawValue, 0.f);
		PillarMesh.SetRelativeLocationAndRotation(PillarLoc, PillarRot);
	}

	UFUNCTION()
	void Burn()
	{
		if (bBurned)
			return;

		bBurned = true;

		if (SmolderDelay == 0)
			StartSmoldering();
		else
			SmolderTimerHandle = System::SetTimer(this, n"StartSmoldering", SmolderDelay, false);

		if (SinkDistance != 0)
		{
			if (SinkDelay == 0)
				StartSinking();
			else
				SinkTimerHandle = System::SetTimer(this, n"StartSinking", SinkDelay, false);
		}

		if (FireDelay == 0)
			StartFire();
		else
			FireTimerHandle = System::SetTimer(this, n"StartFire", FireDelay, false);
	}

	UFUNCTION()
	void StartSmoldering()
	{
		SmolderTimeLike.SetPlayRate(1/SmolderTime);
		SmolderTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void UpdateSmolder(float CurValue)
	{
		MaterialInstance.SetScalarParameterValue(n"Coalness", CurValue);
		SmolderShakiness = CurValue;
	}

	UFUNCTION()
	void StartSinking()
	{
		SinkTimeLike.SetPlayRate((1.f/(SinkDistance/100.f)) * SinkSpeed);
		SinkTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void UpdateSink(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(FVector::ZeroVector, SinkTransform.Location, CurValue);
		FRotator CurRot = FMath::LerpShortestPath(FRotator::ZeroRotator, SinkTransform.Rotation.Rotator(), CurValue);
		Pivot.SetRelativeLocationAndRotation(CurLoc, CurRot);
	}

	UFUNCTION()
	void StartFire()
	{
		FireEffect.Activate();
		FireTimeLike.SetPlayRate(0.2f);
		FireTimeLike.PlayFromStart();

		if (bPlayersOnPillar)
		{
			TArray<AFireRespawnTunnel> Tunnels;
			GetAllActorsOfClass(Tunnels);
			
			AFireRespawnTunnel Tunnel = Tunnels[0];
			if (Tunnel != nullptr)
			{
				Tunnel.ActivateTunnel();
			}
		}
	}

	UFUNCTION()
	void UpdateFire(float CurValue)
	{
		MaterialInstance.SetScalarParameterValue(n"Glowness", CurValue * 2800.f);
		HazeSphereComp.SetOpacityValue(CurValue * 0.5f);
	}

	UFUNCTION()
	void FinishFire()
	{
		FireEffect.Deactivate();
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayersEnteredTrigger(AHazeActor Actor)
	{
		Burn();
	}

	UFUNCTION()
	void ResetPillar()
	{
		SmolderTimeLike.Stop();
		SinkTimeLike.Stop();
		FireTimeLike.Stop();

		Pivot.SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);
		PillarMesh.SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);

		ShakeTime = 0.f;
		SmolderShakiness = 0.f;
		MaterialInstance.SetScalarParameterValue(n"Coalness", 0.f);
		MaterialInstance.SetScalarParameterValue(n"Glowness", 0.f);
		HazeSphereComp.SetOpacityValue(0.f);
		FireEffect.Deactivate();

		System::ClearAndInvalidateTimerHandle(SmolderTimerHandle);
		System::ClearAndInvalidateTimerHandle(SinkTimerHandle);
		System::ClearAndInvalidateTimerHandle(FireTimerHandle);

		bBurned = false;
		bPlayersOnPillar = false;
	}
}