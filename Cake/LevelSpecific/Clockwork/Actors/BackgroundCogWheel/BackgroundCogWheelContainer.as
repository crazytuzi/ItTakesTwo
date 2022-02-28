import Cake.LevelSpecific.Clockwork.Actors.BackgroundCogWheel.BackgroundCogWheelMesh;
import Vino.Audio.AudioActors.HazeAmbientSound;

#if EDITOR
import void ConvertAllInsideRange(ABackgroundCogWheelContainer Container) from "Cake.Environment.SpinningCogWheel";
#endif


class ABackgroundCogWheelContainer : AHazeActor
{	
	default SetActorTickInterval(0);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.bVisualizeComponent = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CogRoot;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 5000;
	default DisableComponent.bActorIsVisualOnly = true;
	default DisableComponent.bRenderWhileDisabled = true;

	// If we convert from the spinning wheel, this needs to be set
	UPROPERTY(EditInstanceOnly, Category = "EDITOR ONLY")
	bool bActiveConverterContainer = false;

	// If we want to collect all actors in range, this can be used. 0 == everyone
	UPROPERTY(EditInstanceOnly, Category = "EDITOR ONLY")
	float ConversionRange = 0.f;

	UPROPERTY(EditAnywhere, Category = "Cogs")
	TArray<FCogData> MeshData;

	UPROPERTY(EditConst, Category = "Cogs")
	TArray<UBackgroundCogWheelMesh> Meshes;

	UPROPERTY(EditInstanceOnly, Category = "Audio")
	TArray<FCogAudioData> AudioData;

	bool bHasRenderedAnything = true;
	float LastRenderTime = 0;
	
	bool bDebugHasEverRenderedMeshes = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		GenerateCogs();
	}

	void GenerateCogs()
	{
		if(MeshData.Num() == 0)
		{
			AudioData.Reset();
		}
		else
		{
			TArray<FCogAudioData> NewAudioData;
			for(int i = 0; i < MeshData.Num(); ++i)
			{
				if(MeshData[i].AudioArrayIndex < 0)
					continue;
				
				MeshData[i].AudioArrayIndex = NewAudioData.Num();
				NewAudioData.Add(AudioData[MeshData[i].AudioArrayIndex]);
				NewAudioData[NewAudioData.Num() - 1].MeshArrayIndex = i;
			}

			AudioData = NewAudioData;
		}

		for(int i = 0; i < Meshes.Num(); ++i)
		{
			if(Meshes[i] != nullptr)
				Meshes[i].DestroyComponent(this);
		}
		Meshes.Reset(MeshData.Num());

		for(int i = 0; i < MeshData.Num(); ++i)
		{
			const FName CreationName = MeshData[i].NameToUse != NAME_None ? FName("" + i + "_" + MeshData[i].NameToUse.ToString()) : FName("Cog_" + i);
			auto NewMesh = Cast<UBackgroundCogWheelMesh>(CreateComponent(UBackgroundCogWheelMesh::StaticClass(), CreationName));
			NewMesh.AttachToComponent(CogRoot);
			NewMesh.SetWorldTransform(MeshData[i].WorldTransform);
			NewMesh.SetStaticMesh(MeshData[i].MeshToUse);
			MeshData[i].RotationPerSteps = 360.0f / float(MeshData[i].Steps);
			MeshData[i].TimeBetweenSteps = MeshData[i].TimeForFullCircle / float(MeshData[i].Steps);
			MeshData[i].Counter = MeshData[i].TimeBetweenSteps;
			Meshes.Add(NewMesh);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Validation
		if(Meshes.Num() != MeshData.Num())
		{
			SetActorTickEnabled(false);	
			Log("Actor: " + GetName() + " is broken and needs to be regenerated");
			devEnsure(false);
		}
		else
		{
			for(int i = 0; i < Meshes.Num(); ++i)
			{
				Meshes[i].InitializeRotators(MeshData[i]);
			}
		}

		// Initalize all the start events needed
		const float GameTime = Time::GetGameTimeSeconds();
		for(int i = 0; i < AudioData.Num(); ++i)
		{
			auto& AudioIndex = AudioData[i];
			const auto& MeshDataIndex = MeshData[AudioIndex.MeshArrayIndex];
			ensure(MeshDataIndex.AudioArrayIndex == i);

			AudioIndex.NextAudioUpdateTime = GameTime + AudioIndex.InitalDelay + MeshDataIndex.TimeBetweenSteps;
			if(AudioIndex.Type != ECogAudioDataType::BeginPlay)
				continue;

			const FVector WorldLocation = Meshes[AudioIndex.MeshArrayIndex].GetWorldLocation();
			UHazeAkComponent::HazePostEventFireForget(AudioIndex.Event, FTransform(WorldLocation));
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		for(int i = 0; i < AudioData.Num(); ++i)
		{
			if(AudioData[i].Type != ECogAudioDataType::BeginPlay)
				continue;

			UHazeAkComponent::HazeStopEventFireForget(AudioData[i].Event);
		}

		// Debug
	#if EDITOR
		// We can validate if this has ever rendered any meshes
		
		if(!bDebugHasEverRenderedMeshes)
		{
			FString ObjectName = "" + GetName() + " in " + Level.Outer.GetName(); 
			Log("[Warning] " + ObjectName + " has never rendered any meshes. Consider removing it");
		}
		else
		{
			FString ObjectName = "" + GetName() + " in " + Level.Outer.GetName(); 
			bool bPrintWarning = false;
			FString PrintWarningText;
			for(int i = 0; i < Meshes.Num(); ++i)
			{
				if(Meshes[i].bDebugHasEverBeenUpdated)
					continue;

				bPrintWarning = true;
				PrintWarningText += "" + Meshes[i].GetName() + "\n";
			}

			if(bPrintWarning)
				Log("[Warning] " + ObjectName + " has not rendered following cogs. Consider removing them:\n" + PrintWarningText);
		}
	#endif

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const float GameTime = Time::GetGameTimeSeconds();
		if(bHasRenderedAnything || GameTime > LastRenderTime + 0.5f)
		{		
			bHasRenderedAnything = false;
			LastRenderTime = GameTime;
			for(int i = 0; i < Meshes.Num(); ++i)
			{
				if(!Meshes[i].WasRecentlyRendered(4.f))
					continue;
				
				Meshes[i].UpdateCog(MeshData[i], GameTime);
				bHasRenderedAnything = true;

			#if EDITOR
			// Debug so we can see what containers never render meshes
				bDebugHasEverRenderedMeshes = true;
			#endif
			}
		}

		for(int i = 0; i < AudioData.Num(); ++i)
		{
			auto& AudioIndex = AudioData[i];

			if(AudioIndex.Type == ECogAudioDataType::BeginPlay)
				continue;

			if(GameTime < AudioData[i].NextAudioUpdateTime)
				continue;

			const auto& MeshDataIndex = MeshData[AudioIndex.MeshArrayIndex];
			ensure(MeshDataIndex.AudioArrayIndex == i);

			AudioIndex.NextAudioUpdateTime += MeshData[AudioIndex.MeshArrayIndex].TimeBetweenSteps;
			if(AudioIndex.Type == ECogAudioDataType::Tick)
			{
				const FVector WorldLocation = Meshes[AudioIndex.MeshArrayIndex].GetWorldLocation();
				UHazeAkComponent::HazePostEventFireForget(AudioIndex.Event, FTransform(WorldLocation));
			}
			else if(AudioIndex.Type == ECogAudioDataType::Ambient)
			{
				AudioIndex.AmbientSoundActor.HazeAkComp.HazePostEvent(AudioIndex.Event);
			}
		}
	}


	#if EDITOR
	// This will convert all the spinning cogs in range of this actors into static meshes inside this actor
	UFUNCTION(CallInEditor, Category = "EDITOR ONLY")
	void ConvertAllInRange()
	{
		ConvertAllInsideRange(this);
	}

	// This will move the actor to the center of the cogs and update the disable range to cover the actor
	UFUNCTION(CallInEditor, Category = "EDITOR ONLY")
	void UpdateDisableComponentRangeAndRootPosition()
	{
		FVector Origin = FVector::ZeroVector;
		FVector Extends = FVector::ZeroVector;
		GetActorBounds(false, Origin, Extends);

		const FVector OldRootLocation = CogRoot.GetWorldLocation();
		SetActorLocation(Origin);
		CogRoot.SetWorldLocation(OldRootLocation);

		DisableComponent.AutoDisableRange = FMath::Max(FMath::Max(Extends.X, Extends.Y), Extends.Z);
		DisableComponent.AutoDisableRange *= FMath::Sqrt(3.f);
		DisableComponent.AutoDisableRange *= 1.5f;
		DisableComponent.AutoDisableRange = FMath::CeilToInt(DisableComponent.AutoDisableRange);
	}

	UFUNCTION(CallInEditor, Category = "EDITOR ONLY")
	void RepairArray()
	{
		GenerateCogs();
	}

	#endif
};