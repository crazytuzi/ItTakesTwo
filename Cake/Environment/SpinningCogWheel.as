import Cake.LevelSpecific.Clockwork.Actors.BackgroundCogWheel.BackgroundCogWheelContainer;

event void UpdateRotatorMovement();

#if EDITOR
void ConvertAllInsideRange(ABackgroundCogWheelContainer Container)
{
	TArray<ASpinningCogWheel> Wheels;
	GetAllActorsOfClass(Wheels);
	for(int i = 0; i < Wheels.Num(); ++i)
	{
		// Check if we want to validate the range and are inside
		if(Container.ConversionRange > 0 && Wheels[i].GetActorLocation().DistSquared(Container.GetActorLocation()) > FMath::Square(Container.ConversionRange))
			continue;

		// Actors with disable components are considered to be hero actors and will not be added
		auto DisableComponent = UHazeDisableComponent::Get(Wheels[i]);
		if(DisableComponent != nullptr)
			continue;

		// Make the conversion
		Wheels[i].ConvertAndAddToContainer(Container);
	}
}

#endif

class ASpinningCogWheel : AHazeActor
{	
	// This is the lowest amount I can set without it showing
	default SetActorTickInterval(1.f / 25.f);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent StaticMeshComponent;
	default StaticMeshComponent.bGenerateOverlapEvents = false;
	
	// Exposed Public Properties
	UPROPERTY(Category="Default")
	float TimeForFullCircle;
	default TimeForFullCircle = 60.0f;

	UPROPERTY(Category="Default")
	int Steps;
	default Steps = 18;

	UPROPERTY(Category="Default")
	bool Reverse;
	default Reverse = false;

	UPROPERTY(Category="Default")
	UCurveFloat Timeline;
	default Timeline = Asset("/Game/Blueprints/Curves/CogwheelCurve");

	UPROPERTY(EditInstanceOnly, Category="EDITOR ONLY")
	bool bAboutToBeConverted = false;

	UPROPERTY(EditConst)
	float RotationPerSteps;

	UPROPERTY(EditConst)
	float TimeBetweenSteps;

	UPROPERTY()
	UpdateRotatorMovement AudioUpdateRotator;

	UFUNCTION(BlueprintEvent)
	void BP_UpdateRotator()
	{}

	UFUNCTION(BlueprintEvent)
	FCogAudioData BP_FillAudioEvent() const
	{
		return FCogAudioData();
	}

	FRotator StartRot;
	FRotator TargetRot;

	UPROPERTY(EditConst)
	float Counter;

	UPROPERTY(Category="Default")
	UStaticMesh MeshToUse;
	default MeshToUse = Asset("/Game/Environment/Props/Fantasy/Tree/Contraptions/CogWheel_Large_01");

	void UpdateRotators()
	{
		float Direction = Reverse ? -1.0f : 1.0f;
		StartRot = StaticMeshComponent.RelativeRotation;
		TargetRot = StartRot;
		TargetRot.Roll += RotationPerSteps * Direction;
		BP_UpdateRotator();
		AudioUpdateRotator.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		StaticMeshComponent.SetStaticMesh(MeshToUse);
		RotationPerSteps = 360.0f / float(Steps);
		TimeBetweenSteps = TimeForFullCircle / float(Steps);	
		Counter = TimeBetweenSteps;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bAboutToBeConverted)
		{
#if !EDITOR
			DestroyActor();
			return;
#endif
		}

		// Without any disable component, the cogs will not be rendered or updated
		if(UHazeDisableComponent::Get(this) == nullptr && !bAboutToBeConverted)
		{
			devEnsure(false, "" + GetName() + " dont have a disable component and will be removed in cook.");

			SetActorTickEnabled(false);
		#if !EDITOR
			DestroyActor();
		#endif
		}
		else
		{
			UpdateRotators();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float Deltatime)
	{
		// Get the fraction of how far the wheel ought to have turned 0.0f .. 1.0f
		float StepTime = 1.0 - Counter / (TimeBetweenSteps); 

		// Offset 0.0 .. 1.0 => -1.0 .. 1.0 so that we later can clamp 
		// this value to sample 0 from the curve to imitate a delay.
		float OffsetStepTime = StepTime * 2.0 - 1.0; 

		// Print(""+ (1.0 - Counter / (TimeBetweenSteps)));
		float Alpha = Timeline.GetFloatValue(Math::Saturate(OffsetStepTime));

		StaticMeshComponent.SetRelativeRotation(
			FRotator(FQuat::FastLerp(FQuat(StartRot), FQuat(TargetRot), Alpha))
		);

		// Remove deltatime from the time a step is given.
		Counter -= Deltatime;

		// Once we drop below 0.0 get a new starting rotation and target, and
		// reset the Counter to what a step is given in time.
		if (Counter < 0.0f)
		{
			UpdateRotators();
			Counter += TimeBetweenSteps;
		}
	}

	#if EDITOR
	
	/** This will convert the cog into a static mesh in the container instead. All the data on this will be kept.
	* You need to place a BackgroundCogWheelContainer in the level and tick the bActiveConverterContainer box
	*/
	UFUNCTION(CallInEditor, Category = "EDITOR ONLY")
	void ConvertActor()
	{
		if(UHazeDisableComponent::Get(this) != nullptr)
		{
			devEnsure(false, "This cog has a disable component and can't be converted.");
			return;
		}

		TArray<ABackgroundCogWheelContainer> BackgroundContainers;
		ABackgroundCogWheelContainer ActiveContainer = nullptr;
		GetAllActorsOfClass(BackgroundContainers);
		if(BackgroundContainers.Num() == 0)
		{
			devEnsure(false, "Could not find any BackgroundCogWheelContainer. Make sure there is atleast one");
			return;
		}

		for(int i = 0; i < BackgroundContainers.Num(); ++i)
		{
			if(!BackgroundContainers[i].bActiveConverterContainer)
				continue;
			
			if(ActiveContainer != nullptr)
			{
				devEnsure(false, "Multiple BackgroundCogWheelContainer has the bool ActiveConverterContainer active");
			}

			ActiveContainer = BackgroundContainers[i];
		}
		
		if(ActiveContainer != nullptr)
		{
			ConvertAndAddToContainer(ActiveContainer);
		}
		else
		{
			devEnsure(false, "Could not find exactly 1 ABackgroundCogWheelContainer. Make sure only 1 level is loaded with this");
		}
	}

	void ConvertAndAddToContainer(ABackgroundCogWheelContainer Container)
	{
		FCogData NewCog;
		NewCog.MeshToUse = MeshToUse;
		NewCog.WorldTransform = GetActorTransform();
		NewCog.NameToUse = Name;
		NewCog.TimeForFullCircle = TimeForFullCircle;
		NewCog.Steps = Steps;
		NewCog.Reverse = Reverse;
		NewCog.Timeline = Timeline;
		
		FCogAudioData AudioData = BP_FillAudioEvent();
		if(AudioData.Type != ECogAudioDataType::UnUsed)
		{
			AudioData.MeshArrayIndex = Container.MeshData.Num();
			NewCog.AudioArrayIndex = Container.AudioData.Num();
			Container.AudioData.Add(AudioData);
		}

		Container.MeshData.Add(NewCog);
		Container.GenerateCogs();
		DestroyActor();
	}

	#endif
}