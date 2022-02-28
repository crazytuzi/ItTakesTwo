import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.PlayerHealth.PlayerHealthStatics;

class AGreenhouseBossGrowingThorns : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent)
    UBillboardComponent Billboard;
	default Billboard.Sprite = Asset("/Game/Editor/EditorBillboards/Godray.Godray");
	default Billboard.bIsEditorOnly = true;
#if EDITOR
	default Billboard.bUseInEditorScaling = true;
#endif
    UPROPERTY(DefaultComponent)
    UStaticMeshComponent MeshComp;
	default MeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;

    UPROPERTY(DefaultComponent)
	UBoxComponent PlayerKiller;
    //default PlayerKiller.bShouldUpdatePhysicsVolume = true;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

    UPROPERTY()
	float BlendTime = 2.0f;

    UPROPERTY()
	float CollisionBoxScale = 0.8f;

    UPROPERTY()
	bool StartWithered = false;

    UPROPERTY(Category="DO NOT TOUCH")
	float TargetBlendValue = 0;

    UPROPERTY(Category="DO NOT TOUCH")
	float CurrentBlendValue = 0;

	UFUNCTION(CallInEditor)
    void Wither()
    {
		TargetBlendValue = 1.0f;
	}
	UFUNCTION(CallInEditor)
    void UnWither()
    {
		TargetBlendValue = 0.0f;
	}
	UFUNCTION(CallInEditor)
    void WitherInstant()
    {
		TargetBlendValue = 1.0f;
		CurrentBlendValue = 1.0f;
	}
	UFUNCTION(CallInEditor)
    void UnWitherInstant()
    {
		TargetBlendValue = 0.0f;
		CurrentBlendValue = 0.0f;
	}
	
	void UpdateCollisionBlend(float x)
	{
		float ExtentX = MeshComp.StaticMesh.BoundingBox.Extent.X;
		FVector Offset = PlayerKiller.ForwardVector * (2 * ExtentX + (CollisionBoxScale * -ExtentX * 2) * (1 - x));
		PlayerKiller.SetWorldLocation(MeshComp.GetShapeCenter() + Offset);
		//PlayerKiller.SetBoxExtent(FVector(CollisionBoxScale * ExtentX * (1 - x), MeshComp.StaticMesh.BoundingBox.Extent.Y, MeshComp.StaticMesh.BoundingBox.Extent.Z));
		MeshComp.SetVisibility(x < 1);
	}

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		UpdateCollisionBlend(TargetBlendValue);
		if(StartWithered)
			UpdateCollisionBlend(1);

		PlayerKiller.SetBoxExtent(MeshComp.StaticMesh.BoundingBox.Extent);
	}

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(StartWithered)
			WitherInstant();
		else
			UnWitherInstant();

		UpdateCollisionBlend(TargetBlendValue);
		if(StartWithered)
			UpdateCollisionBlend(1);

        PlayerKiller.OnComponentBeginOverlap.AddUFunction(this, n"OverlappedPlayer");
	}

    float MoveTowards(float Current, float Target, float StepSize)
    {
        return Current + FMath::Clamp(Target - Current, -StepSize, StepSize);
    }

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CurrentBlendValue = MoveTowards(CurrentBlendValue, TargetBlendValue, DeltaTime / BlendTime);
		MeshComp.SetScalarParameterValueOnMaterials(n"BlendValue", CurrentBlendValue);

		UpdateCollisionBlend(CurrentBlendValue);
	}

    UFUNCTION()
    void OverlappedPlayer(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
								 UPrimitiveComponent OtherComponent, int OtherBodyIndex,
								 bool bFromSweep, FHitResult& Hit)
    {
		if(CurrentBlendValue >= 1.0f)
			return;
		
		AHazePlayerCharacter PlayerCharacter = Cast<AHazePlayerCharacter>(OtherActor);
		if(PlayerCharacter == nullptr)
			return;
		
		KillPlayer(PlayerCharacter, DeathEffect);
    }
}