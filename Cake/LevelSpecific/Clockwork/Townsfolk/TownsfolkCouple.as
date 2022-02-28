import Cake.LevelSpecific.Clockwork.Townsfolk.TownsfolkActor;

class ATownsfolkCouple : ATownsfolkActor
{
	default WalkSpeed = 1000.f;
	default DisableComponent.bAutoDisable = false;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = Base)
	UNiagaraComponent GlimmerEffectComp;

	UPROPERTY()
	TSubclassOf<UHazeCapability> AudioCapabilityClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> GrindCapabilityClass;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UClass AudioClass = AudioCapabilityClass.Get();
		if(AudioClass != nullptr)		
			AddCapability(AudioClass);		
			
		Super::BeginPlay();

		if (GrindCapabilityClass.Get() != nullptr)
			Capability::AddPlayerCapabilityRequest(GrindCapabilityClass);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		if (GrindCapabilityClass.Get() != nullptr)
			Capability::RemovePlayerCapabilityRequest(GrindCapabilityClass);
	}

	UFUNCTION()
	void SetPlatformVisibility(bool bVisible)
	{
		Platform.SetHiddenInGame(!bVisible);
	}

	UFUNCTION()
	void SetGlimmerVisibility(bool bVisible)
	{
		if (bVisible)
			GlimmerEffectComp.Activate(true);
		else
			GlimmerEffectComp.Deactivate();
	}
};

UFUNCTION()
void TeleportTownsfolkCoupleTo(AActor LeftSpline, AActor RightSpline)
{
	TArray<ATownsfolkCouple> Couple;
	GetAllActorsOfClass(Couple);

	Couple[0].StartMovingOnSpline(LeftSpline, bSnapToStartOfSpline = true);
	Couple[1].StartMovingOnSpline(RightSpline, bSnapToStartOfSpline = true);
}