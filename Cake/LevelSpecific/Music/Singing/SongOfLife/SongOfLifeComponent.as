import Cake.LevelSpecific.Music.Singing.SingingSettings;
import Cake.LevelSpecific.Music.Singing.SongOfLife.SongOfLifeInfo;

class USongOfLifeContainerComponent : UActorComponent
{
	TArray<USongOfLifeComponent> SongOfLifeCollection;
}

#if EDITOR
class USongOfLifePreviewComponent : UNiagaraComponent
{
	
}
#endif // EDITOR

UCLASS(hidecategories = "Collision AssetUserData ComponentReplication Activation Rendering Tags Physics")
class USongOfLifeComponent : UHazeActivationPoint
{
	default InitializeDistance(EHazeActivationPointDistanceType::Visible, 0.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Targetable, 0.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Selectable, 0.f);
	default BiggestDistanceType = EHazeActivationPointDistanceType::Visible;
	default ValidationIdentifier = EHazeActivationPointIdentifierType::LevelSpecific;
	default ValidationType = EHazeActivationPointActivatorType::May;

	private bool bAffectedBySongOfLife = false;

	bool IsAffectedBySongOfLife() const { return bAffectedBySongOfLife; }

	private bool bSongOfLifeDisabled = false;

	default WidgetClass = Asset("/Game/Blueprints/LevelSpecific/Music/Singing/SongOfLife/WBP_SongOfLifeWidget.WBP_SongOfLifeWidget_C");

	UPROPERTY(Category = VFX)
	UNiagaraSystem SongOfLifeVFX = Asset("/Game/Effects/Niagara/SongOfLife/GameplaySOL_02.GameplaySOL_02");

	UPROPERTY()
	FSongOfLifeDelegate OnStartAffectedBySongOfLife;

	UPROPERTY()
	FSongOfLifeDelegate OnStopAffectedBySongOfLife;

	UPROPERTY(Category = VFX)
	float VFXSizeMulti = 1.0f;

	UPROPERTY(Category = Debug)
	bool bEnableVFXPreview = true;

	/* 
		This bool is set in a capability to enable it being affected despite being behind the camera.
		It's not for anything visual but so that the player can affect targets behind the camera.
	*/
	bool bSongOfLifeInRange = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		USongOfLifeContainerComponent SongContainer = USongOfLifeContainerComponent::GetOrCreate(Game::GetMay());

		if(SongContainer.SongOfLifeCollection.Num() == 0)
			Reset::RegisterPersistentComponent(SongContainer);

		SongContainer.SongOfLifeCollection.Add(this);

#if EDITOR
		RemovePreviewComponent();
#endif // EDITOR
	}

#if EDITOR
	private void RemovePreviewComponent()
	{
		USongOfLifePreviewComponent PreviewComp = Cast<USongOfLifePreviewComponent>(Owner.GetComponentByClass(USongOfLifePreviewComponent::StaticClass()));

		if(PreviewComp != nullptr)
		{
			PreviewComp.Deactivate();
			PreviewComp.DestroyComponent(Owner);
		}
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(SongOfLifeVFX != nullptr && bEnableVFXPreview)
		{
			USongOfLifePreviewComponent PreviewComp = Cast<USongOfLifePreviewComponent>(Owner.GetComponentByClass(USongOfLifePreviewComponent::StaticClass()));

			if(PreviewComp == nullptr)
			{
				PreviewComp = USongOfLifePreviewComponent::Create(Owner);
				PreviewComp.bIsEditorOnly = true;
				PreviewComp.AttachToComponent(this);
				PreviewComp.SetAsset(SongOfLifeVFX);
			}

			if(PreviewComp != nullptr && bEnableVFXPreview)
			{
				PreviewComp.Activate();
				PreviewComp.SetVariableFloat(n"SizeMulti", VFXSizeMulti);
			}
		}
		else if(!bEnableVFXPreview)
		{
			RemovePreviewComponent();
		}
	}
#endif // EDITOR

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		USongOfLifeContainerComponent SongContainer = USongOfLifeContainerComponent::GetOrCreate(Game::GetMay());
		bool bHadReactions = SongContainer.SongOfLifeCollection.Num() != 0;
		SongContainer.SongOfLifeCollection.Remove(this);

		if (bHadReactions && SongContainer.SongOfLifeCollection.Num() == 0)
			Reset::UnregisterPersistentComponent(SongContainer);
	}

	UFUNCTION(BlueprintPure)
	FRotator GetVFXRotation() const
	{
		return Owner.ActorRotation;
	}

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const
	{	
		if(bSongOfLifeDisabled)
			return EHazeActivationPointStatusType::InvalidAndHidden;

		if(!bSongOfLifeInRange)
			return EHazeActivationPointStatusType::Invalid;

		return EHazeActivationPointStatusType::Valid;
	}

	UFUNCTION(BlueprintOverride)
	float SetupGetDistanceForPlayer(AHazePlayerCharacter Player, EHazeActivationPointDistanceType Type) const
	{
		USingingSettings SingingSettings = USingingSettings::GetSettings(Player);

		if(SingingSettings == nullptr)
			return GetDistance(Type);

		if(Type == EHazeActivationPointDistanceType::Selectable)
			return SingingSettings.SongOfLifeRange;
		else if(Type == EHazeActivationPointDistanceType::Targetable)
			return SingingSettings.SongOfLifeRange * 1.4f;
		else if(Type == EHazeActivationPointDistanceType::Visible)
			return SingingSettings.SongOfLifeRange * 1.8f;

		return GetDistance(Type);
	}

	UFUNCTION()
	void DisableSongOfLife()
	{
		if(bAffectedBySongOfLife)
		{
			FSongOfLifeInfo Info;
			StopAffectedBySongOfLife(Info);
		}

		bSongOfLifeDisabled = true;
	}

	void EnableSongOfLife()
	{
		bSongOfLifeDisabled = false;
	}

	void StartAffectedBySongOfLife(FSongOfLifeInfo Info)
	{
		if(bAffectedBySongOfLife || bSongOfLifeDisabled)
			return;

		bAffectedBySongOfLife = true;
		OnStartAffectedBySongOfLife.Broadcast(Info);
	}

	void StopAffectedBySongOfLife(FSongOfLifeInfo Info)
	{
		if(!bAffectedBySongOfLife || bSongOfLifeDisabled)
			return;

		bAffectedBySongOfLife = false;
		OnStopAffectedBySongOfLife.Broadcast(Info);
	}
}
