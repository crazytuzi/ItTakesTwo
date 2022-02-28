enum ETemporalLogVisualizationType
{
	Point,
	Line,
	Capsule,
	Sphere,
	Circle,
	Box,
	Camera,
	Animation,
};

struct FTemporalLogVisualization
{
	ETemporalLogVisualizationType Type = ETemporalLogVisualizationType::Point;
	FVector Origin;
	FVector Target;
	FRotator Rotation;
	float Weight = 1.f;
	bool bDrawByDefault = false;
	FLinearColor Color;
	UObject Asset;

	void Draw(float Duration = 0.f) const
	{
		switch(Type)
		{
			case ETemporalLogVisualizationType::Point:
				System::DrawDebugPoint(Origin, Weight, Color, Duration);
			break;
			case ETemporalLogVisualizationType::Line:
				System::DrawDebugLine(Origin, Target, Color, Duration, Weight);
			break;
			case ETemporalLogVisualizationType::Capsule:
				System::DrawDebugCapsule(Origin, Target.X, Target.Y, Rotation, Color, Duration, Weight);
			break;
			case ETemporalLogVisualizationType::Sphere:
				System::DrawDebugSphere(Origin, Target.X, 20, Color, Duration, Weight);
			break;
			case ETemporalLogVisualizationType::Box:
				System::DrawDebugBox(Origin, Target, Color, Rotation, Duration, Weight);
			break;
			case ETemporalLogVisualizationType::Circle:
				System::DrawDebugCircle(Origin, Target.X, FMath::CeilToInt(Target.Y), Color, Duration, Weight, Rotation.Yaw, Rotation.Pitch);
			break;
		}
	}
};

struct FTemporalLogVisualizationEvent
{
	TArray<FTemporalLogVisualization> Visualizations;
};

event void FTemporalLogCallbackFunction(AHazeActor Actor, UTemporalLogFrame Frame);
struct FTemporalLogCallback
{
	FString Label;
	FTemporalLogCallbackFunction Callback;
};

class UTemporalLogObject
{
	UPROPERTY()
	FName Category;

	UPROPERTY()
	FName ObjectName; 

	UPROPERTY()
	FString Summary; 

	UPROPERTY()
	FLinearColor ObjectColor;

	UPROPERTY()
	TMap<FName, FString> Values;

	UPROPERTY()
	TMap<FName, FTemporalLogVisualizationEvent> Visualizations;

	UPROPERTY()
	FTemporalLogCallback Callback;

	void LogValue(FName InName, FString Value)
	{
		Values.Add(InName, Value);
	}

	void LogValue(FName InName, float Value)
	{
		Values.Add(InName, ""+Value);
	}

	void LogValue(FName InName, FVector Value)
	{
		Values.Add(InName, ""+Value);
	}

	void LogValue(FName InName, FName Value)
	{
		Values.Add(InName, ""+Value);
	}

	void LogPoint(FName InName, FVector Point, FLinearColor Color = FLinearColor::White, bool bDrawByDefault = false, float Thickness = 5.f)
	{
		FString& Text = Values.FindOrAdd(InName);
		if (Text.Len() != 0)
			Text += "\n";
		Text += "Point:"+Point;

		FTemporalLogVisualization Vis;
		Vis.Type = ETemporalLogVisualizationType::Point;
		Vis.bDrawByDefault = bDrawByDefault;
		Vis.Weight = Thickness;
		Vis.Origin = Point;
		Vis.Color = Color;

		Visualizations.FindOrAdd(InName).Visualizations.Add(Vis);
	}

	void LogLine(FName InName, FVector Origin, FVector Target, FLinearColor Color = FLinearColor::White, bool bDrawByDefault = false, float Thickness = 2.f, bool bAddAsText = true)
	{
		if (bAddAsText)
		{
			FString& Text = Values.FindOrAdd(InName);
			if (Text.Len() != 0)
				Text += "\n";
			Text += "Line: "+Origin+" => "+Target;
		}

		FTemporalLogVisualization Vis;
		Vis.Type = ETemporalLogVisualizationType::Line;
		Vis.bDrawByDefault = bDrawByDefault;
		Vis.Weight = Thickness;
		Vis.Origin = Origin;
		Vis.Target = Target;
		Vis.Color = Color;

		Visualizations.FindOrAdd(InName).Visualizations.Add(Vis);
	}

	void LogCapsule(FName InName, FVector Origin, float HalfHeight, float Radius, FLinearColor Color = FLinearColor::White, bool bDrawByDefault = false, float Thickness = 1.f, FRotator Rotation = FRotator::ZeroRotator)
	{
		FString& Text = Values.FindOrAdd(InName);
		if (Text.Len() != 0)
			Text += "\n";
		Text += "Capsule: "+Origin+" (HalfHeight: "+HalfHeight+", Radius: "+Radius+")";

		FTemporalLogVisualization Vis;
		Vis.Type = ETemporalLogVisualizationType::Capsule;
		Vis.bDrawByDefault = bDrawByDefault;
		Vis.Weight = Thickness;
		Vis.Origin = Origin;
		Vis.Rotation = Rotation;
		Vis.Target = FVector(HalfHeight, Radius, 0.f);
		Vis.Color = Color;

		Visualizations.FindOrAdd(InName).Visualizations.Add(Vis);
	}

	void LogSphere(FName InName, FVector Origin, float Radius, FLinearColor Color = FLinearColor::White, bool bDrawByDefault = false, float Thickness = 1.f)
	{
		FString& Text = Values.FindOrAdd(InName);
		if (Text.Len() != 0)
			Text += "\n";
		Text += "Sphere: "+Origin+" (Radius: "+Radius+")";

		FTemporalLogVisualization Vis;
		Vis.Type = ETemporalLogVisualizationType::Sphere;
		Vis.bDrawByDefault = bDrawByDefault;
		Vis.Weight = Thickness;
		Vis.Origin = Origin;
		Vis.Target = FVector(Radius, 0.f, 0.f);
		Vis.Color = Color;

		Visualizations.FindOrAdd(InName).Visualizations.Add(Vis);
	}

	void LogBox(FName InName, FVector Origin, FVector Extents, FLinearColor Color = FLinearColor::White, bool bDrawByDefault = false, float Thickness = 5.f, FRotator Rotation = FRotator::ZeroRotator)
	{
		FString& Text = Values.FindOrAdd(InName);
		if (Text.Len() != 0)
			Text += "\n";
		Text += "Box: "+Origin+" (Extents: "+Extents+")";

		FTemporalLogVisualization Vis;
		Vis.Type = ETemporalLogVisualizationType::Box;
		Vis.bDrawByDefault = bDrawByDefault;
		Vis.Weight = Thickness;
		Vis.Origin = Origin;
		Vis.Rotation = Rotation;
		Vis.Target = Extents;
		Vis.Color = Color;

		Visualizations.FindOrAdd(InName).Visualizations.Add(Vis);
	}

	void LogCircle(FName InName, FVector Origin, float Radius, int Segments = 12, FLinearColor Color = FLinearColor::White, bool bDrawByDefault = false, float Thickness = 5.f, FVector YAxis = FVector::RightVector, FVector ZAxis = FVector::UpVector)
	{
		FString& Text = Values.FindOrAdd(InName);
		if (Text.Len() != 0)
			Text += "\n";
		Text += "Circle: "+Origin+" (Radius: "+Radius+")";

		FTemporalLogVisualization Vis;
		Vis.Type = ETemporalLogVisualizationType::Circle;
		Vis.bDrawByDefault = bDrawByDefault;
		Vis.Weight = Thickness;
		Vis.Origin = Origin;
		Vis.Target = FVector(Radius, Segments, 0.f);
		Vis.Color = Color;
		Vis.Rotation = FRotator::MakeFromYZ(YAxis, ZAxis);

		Visualizations.FindOrAdd(InName).Visualizations.Add(Vis);
	}

	void LogCamera(FName InName, FVector Origin, FRotator Rotation, float FOV, FLinearColor Color = FLinearColor::White, bool bDrawByDefault = false, float Thickness = 1.f)
	{
		FString& Text = Values.FindOrAdd(InName);
		if (Text.Len() != 0)
			Text += "\n";
		Text += "Camera: "+Origin;

		FTemporalLogVisualization Vis;
		Vis.Type = ETemporalLogVisualizationType::Camera;
		Vis.bDrawByDefault = bDrawByDefault;
		Vis.Weight = Thickness;
		Vis.Origin = Origin;
		Vis.Rotation = Rotation;
		Vis.Target.X = FOV;
		Vis.Color = Color;

		Visualizations.FindOrAdd(InName).Visualizations.Add(Vis);
	}

	void LogAnimation(FName InName, FVector Location, FRotator Rotation, UAnimationAsset Sequence, float Position, bool bDrawByDefault = false, FVector2D BlendValues = FVector2D())
	{
		FString& Text = Values.FindOrAdd(InName);
		if (Text.Len() != 0)
			Text += "\n";
		Text += "Animation: "+Sequence.Name+" @ "+Position+"s";

		FTemporalLogVisualization Vis;
		Vis.Type = ETemporalLogVisualizationType::Animation;
		Vis.bDrawByDefault = bDrawByDefault;
		Vis.Asset = Sequence;
		Vis.Origin = Location;
		Vis.Rotation = Rotation;
		Vis.Target.X = Position;
		Vis.Target.Y = BlendValues.X;
		Vis.Target.Z = BlendValues.Y;

		Visualizations.FindOrAdd(InName).Visualizations.Add(Vis);
	}

	void SetCallback(FString Label, FTemporalLogCallbackFunction Function)
	{
		Callback.Label = Label;
		Callback.Callback = Function;
	}
};

struct FTemporalLogEvent
{
	FString Event;
};

class UTemporalLogFrame
{
	UPROPERTY()
	uint FrameNumber = 0;

	UPROPERTY()
	float GameTime = -1.f;

	UPROPERTY()
	float DeltaTime = -1.f;

	UPROPERTY()
	FVector ActorLocation;

	UPROPERTY()
	TArray<UTemporalLogObject> Objects;

	UPROPERTY()
	TArray<FTemporalLogEvent> Events;

	UTemporalLogObject GetObjectByName(FName ObjectName)
	{
		for(auto Entry : Objects)
		{
			if (Entry.ObjectName == ObjectName)
				return Entry;
		}
		return nullptr;
	}
};

class UTemporalLogAction
{
	void Log(AHazeActor Actor, UTemporalLogComponent Log) const {}
};

class UTemporalLogComponent : UActorComponent
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	TArray<UTemporalLogFrame> Frames;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bEnabled = true;

	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_LastDemotable;

	private TArray<UTemporalLogAction> Actions;

	FName SelectedCategory;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Reset::RegisterPersistentComponent(this);

		auto CrumbComp = UHazeCrumbComponent::Get(Owner);
		if(CrumbComp != nullptr)
		{
			AddTickPrerequisiteComponent(CrumbComp);
		}

		auto CapaComp = UHazeCapabilityComponent::Get(Owner);
		if(CapaComp != nullptr)
		{
			AddTickPrerequisiteComponent(CapaComp);
		}
	}

	UTemporalLogFrame GetFrame()
	{
		uint CurrentFrameNumber = Time::GetFrameNumber();
		if (Frames.Num() == 0 || Frames.Last().FrameNumber != CurrentFrameNumber)
		{
			UTemporalLogFrame NewFrame = UTemporalLogFrame();
			NewFrame.FrameNumber = CurrentFrameNumber;
			NewFrame.GameTime = Time::GetGameTimeSeconds();
			NewFrame.DeltaTime = Time::GetUndilatedWorldDeltaSeconds();
			NewFrame.ActorLocation = Owner.ActorLocation;

			Frames.Add(NewFrame);
			return NewFrame;
		}
		else
		{
			return Frames.Last();
		}
	}

	UTemporalLogObject LogObject(FName Category, UObject Object, FLinearColor Color = FLinearColor::White, bool bLogProperties = true)
	{
		UTemporalLogObject Entry = UTemporalLogObject();
		Entry.Category = Category;
		Entry.ObjectName = FName(Object.Name);
		Entry.ObjectColor = Color;

		if (bLogProperties)
			DebugObjectProperties(Object, Entry.Values);

		GetFrame().Objects.Add(Entry);
		return Entry;
	}

	void LogEvent(FString Event)
	{
		FTemporalLogEvent Entry;
		Entry.Event = Event;

		GetFrame().Events.Add(Entry);
	}

	void LogAction(UTemporalLogAction Action)
	{
		Actions.Add(Action);
	}

	void SetLogEnabled(bool InEnable)
	{
		bEnabled = InEnable;
		SetComponentTickEnabled(bEnabled);

		if (bEnabled)
		{
			Frames.Empty();
			GetFrame();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (DeltaTime < 0.0001)
			return;

		ensure(bEnabled);
		for (auto Action : Actions)
			Action.Log(Cast<AHazeActor>(Owner), this);
	}
};
