import Peanuts.Triggers.PlayerTrigger;
import Cake.LevelSpecific.SnowGlobe.SnowAngel.PlayerSnowAngelComponent;
import Vino.Tutorial.TutorialStatics;

class ASnowAngelArea : APlayerTrigger
{
	UPROPERTY()
	UHazeCapabilitySheet SnowAngelCapabilitySheet;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	USphereComponent SphereComp;
	default SphereComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap); 

	UPROPERTY()
	TArray<ADecalActor> DecalCompArray;
	ADecalActor LastDecalRef;

	bool bIsActive;

	int MaxDecals = 15;

	bool IsFading;

	float FadeTime = 2.5f;

	UPROPERTY(NotVisible)
	UMaterialInstanceDynamic MaterialInstance;

	UPlayerSnowAngelComponent PlayerSnowAngelComponent;

	UFUNCTION()
	void CheckDecalMaxAmount()
	{
		if (DecalCompArray.Num() > MaxDecals)
		{
			MaterialInstance = Cast<UMaterialInstanceDynamic>(DecalCompArray[0].Decal.DecalMaterial); 
			LastDecalRef = DecalCompArray[0]; 
			if (MaterialInstance == nullptr)
				return;

			MaterialInstance.SetScalarParameterValue(n"FadeStartTime", Time::GetGameTimeSeconds());
			MaterialInstance.SetScalarParameterValue(n"FadeDuration", FadeTime);
			DecalCompArray.RemoveAt(0); 
			System::SetTimer(this, n"DestroyDecalActor", FadeTime, false);
		}
	}

	void DestroyDecalActor()
	{
		LastDecalRef.DestroyActor();
	}

    void EnterTrigger(AActor Actor) override
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);

		if (Player == nullptr)
			return;

		Player.AddCapabilitySheet(SnowAngelCapabilitySheet);

		PlayerSnowAngelComponent = UPlayerSnowAngelComponent::Get(Player);

		if (PlayerSnowAngelComponent == nullptr)
			return;

		Player.SetCapabilityAttributeObject(n"SnowAngelArea", this);

		PlayerSnowAngelComponent.ShowActivateAngelPrompt(Player);
    }

    void LeaveTrigger(AActor Actor) override
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);

		if (Player == nullptr)
			return;

		Player.RemoveCapabilitySheet(SnowAngelCapabilitySheet);

		PlayerSnowAngelComponent = UPlayerSnowAngelComponent::Get(Player);

		if (PlayerSnowAngelComponent == nullptr)
			return;

		PlayerSnowAngelComponent.HideAngelPrompt(Player);

    }

	UFUNCTION()
	void CheckSnowAngelArrayCount()
	{
		if (DecalCompArray.Num() > MaxDecals)
		{
			DecalCompArray[MaxDecals - 1].DestroyActor();
			DecalCompArray[MaxDecals - 1].RemoveFromRoot();
		}
	}

}