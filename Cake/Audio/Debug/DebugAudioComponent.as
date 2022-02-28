import Peanuts.Audio.AudioStatics;
import Peanuts.Audio.AudioSpline.AudioSpline;
import Peanuts.Audio.AmbientZone.AmbientZone;

// Using a component instead of a capability as to allow usage from any object and not just HazeActors (JS)

class UDebugAudioComponent : USceneComponent
{
	UHazeAkComponent HazeAkComp;
	UHazeListenerComponent ClosestListener;	
	AAmbientZone ZoneOwner;
	AAudioSpline SplineOwner;
	
	UPROPERTY()		
	UTextRenderComponent TextComp;
	UPROPERTY()		
	USphereComponent SphereComp;
	
	bool bIsActive = true;
	bool bHasCreatedComponents = false;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{		
		SetComponentActive(false);
		bHasCreatedComponents = false;

		SplineOwner = Cast<AAudioSpline>(GetOwner());		
		ZoneOwner = Cast<AAmbientZone>(GetOwner());	
	}

	void CreateComponents()
	{
		if (bHasCreatedComponents)
			return;
		bHasCreatedComponents = true;

		TextComp = UTextRenderComponent::Create(Owner);			
		TextComp.SetWorldSize(25.f);
		TextComp.SetWorldScale3D(FVector(1.f, 1.f, 1.f));		
		TextComp.SetHorizontalAlignment(EHorizTextAligment::EHTA_Center);
		TextComp.bGenerateOverlapEvents = false;	

		SphereComp = USphereComponent::Create(Owner);
		SphereComp.SetVisibility(false);
		SphereComp.SetSimulatePhysics(false);
		SphereComp.SetShouldUpdatePhysicsVolume(false);
		SphereComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		SphereComp.SetHiddenInGame(false);
		SphereComp.bGenerateOverlapEvents = false;
	}
	
	UFUNCTION()
	bool ShouldActivateComponent() 
	{
		if(HazeAkComp == nullptr)
			return false;
			
		if(HazeAkComp.bDebugAudio)
		{	
			return true;
		}
		else
		{
			return false;	
		}
	}

	UFUNCTION()
	void SetComponentActive(bool bNewState)
	{
		if (bNewState == bIsActive)
			return;
		bIsActive = bNewState;

		if (bIsActive)
			CreateComponents();
		
		if(TextComp != nullptr)
			TextComp.SetVisibility(bIsActive);

		if(SphereComp != nullptr)
			SphereComp.SetVisibility(bIsActive == false ? false : HazeAkComp != nullptr && HazeAkComp.MaxAttenuationRadius > 0);

		if(SplineOwner != nullptr)
			SplineOwner.SetDebug(bIsActive);
		else if(ZoneOwner != nullptr && ZoneOwner.AmbEventComp == HazeAkComp)
			ZoneOwner.SetDebug(bIsActive);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (HazeAkComp == nullptr)
		{
			HazeAkComp = Cast<UHazeAkComponent>(GetAttachParent());	
		}
		if (HazeAkComp == nullptr)
			return;	

		SetComponentActive(ShouldActivateComponent());
		if (!bIsActive)
			return;

		DrawDebugVisuals();
	}

	UHazeCameraComponent GetClosestCamera()
	{
		TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
		TArray<UHazeCameraComponent> PlayerCameras;
		
		for(AHazePlayerCharacter& Player : Players)
		{
			UHazeCameraComponent Camera = UHazeCameraComponent::Get(Player);
			PlayerCameras.AddUnique(Camera);
		}

		float ShortestDist = BIG_NUMBER;
		UHazeCameraComponent ClosestCam = nullptr;

		for(UHazeCameraComponent& Cam : PlayerCameras)
		{
			float CameraDistance = Cam.GetWorldLocation().DistSquared(GetWorldLocation());

			if(CameraDistance > ShortestDist)
				continue;
			
			ShortestDist = CameraDistance;
			ClosestCam = Cam;

		}

		return ClosestCam;
	}

	UFUNCTION()
	void DrawDebugVisuals()
	{
		UHazeCameraComponent Cam = GetClosestCamera();
		ClosestListener = UHazeAkComponent::GetClosestListener(GetWorld(), GetAttachParent().GetWorldLocation());		

		if (TextComp != nullptr)
		{
			FRotator TextRotation = Cam != nullptr ?
				FRotator::MakeFromX(Cam.GetWorldLocation() - GetWorldLocation()).Quaternion().Rotator() :
				FRotator::ZeroRotator;
			TextComp.SetWorldRotation(TextRotation);
			TextComp.SetWorldLocation(FVector(GetAttachParent().GetWorldLocation().X, GetAttachParent().GetWorldLocation().Y, GetAttachParent().GetWorldLocation().Z + 100.f));			
		}

		bool IsAmbientZone = ZoneOwner != nullptr && ZoneOwner.AmbEventComp == HazeAkComp;

		FVector CompLocation = HazeAkComp.GetWorldLocation();
		float DistanceToListener = 
			ClosestListener.GetWorldLocation()
			.Distance(CompLocation);

		FLinearColor Color;
		if (!HazeAkComp.bIsEnabled)
		{
			Color = FLinearColor::Gray;
		}else if (!HazeAkComp.bIsPlaying)
		{
			Color = FLinearColor::Red;
		}else if (HazeAkComp.MaxAttenuationRadius > 0)
		{
			Color = 
				DistanceToListener <= HazeAkComp.ScaledMaxAttenuationRadius ? 
				FLinearColor::Green : FLinearColor::Blue;
		}
		else {
			Color = FLinearColor::Green;
		}
		
		if (IsAmbientZone)
		{
			Color = ZoneOwner.CurrentRtpcValue > 0 ? FLinearColor::Green : FLinearColor::Red;
			FVector Point;

			float Distance = ZoneOwner.GetClosestDistanceOnBrushComponent(ClosestListener.GetWorldLocation(), Point);
			if (Distance != 0)
			{
				CompLocation = Point;
			}
		}

		if(HazeAkComp.MaxAttenuationRadius > 0 )
		{
			if (HazeAkComp.MaxAttenuationRadius != SphereComp.SphereRadius)
				SphereComp.SetSphereRadius(HazeAkComp.ScaledMaxAttenuationRadius);

			Shape::SetShapeColor(SphereComp, Color);
			SphereComp.SetWorldLocation(CompLocation);
		}
		System::DrawDebugPoint(CompLocation, 50.f, PointColor = Color);

		FString EventNames;
		float HeightOffset = 0.0;
		FRotator Rotation = HazeAkComp.WorldRotation;

		for(FHazeAudioEventInstance Instance : HazeAkComp.ActiveEventInstances)
		{
			if (Instance.bUseConeAttenuation)
			{
				System::DrawDebugConeInDegrees(
					CompLocation, 
					Rotation.ForwardVector, 100,
					 Instance.ConeAttenuationInnerAngle, Instance.ConeAttenuationInnerAngle, LineColor = FLinearColor::LucBlue);
				System::DrawDebugConeInDegrees(
					CompLocation, 
					Rotation.ForwardVector, 100,
					 Instance.ConeAttenuationOuterAngle, Instance.ConeAttenuationOuterAngle, LineColor = FLinearColor::Gray);
			}
			// HeightOffset += 50.0;
			EventNames = EventNames + "\n " + Instance.EventName;
		}

		if (IsAmbientZone)
		{
			EventNames += "\n Ambient zone Rtpc: " + ZoneOwner.CurrentRtpcValue;
		}

		UHazeReverbComponent ReverbComp = HazeAkComp.GetReverbComponent(false);
		if (ReverbComp != nullptr)
		{
			auto SendValues = ReverbComp.GetAuxSendValues();
			if (SendValues.Num() > 0)
			{
				EventNames += "\n Reverb SendValues: ";
				for (auto KeyValuePair : SendValues)
				{
					float Value = KeyValuePair.Value;
					EventNames += "" + Value + ", ";
				}
			}
		}

		FString ListenerText = "\n Distance: "+ DistanceToListener + "\n Listener: " + ClosestListener.GetOwner().GetName();
		HeightOffset += 200;

		auto ParentWorldLocation = GetAttachParent().GetWorldLocation();
		if (IsAmbientZone)
			ParentWorldLocation = CompLocation;

		UHazeDisableComponent DisableComp = UHazeDisableComponent::Get(GetOwner());
		if (DisableComp != nullptr)
		{
			ListenerText += "\n DisableComponent, AutoDisable: "+ DisableComp.bAutoDisable +" Range: " + int(DisableComp.AutoDisableRange); 
			// if (DisableComp.AutoDisableRange < HazeAkComp.MaxAttenuationRadius)
			// {
			// 	FString Message = 
			// 		GetAttachParent().GetName() + 
			// 		" disable component disables at a shorter range then the sound plays! "
			// 		+ "Range: " + DisableComp.AutoDisableRange + "vs Audio: " + HazeAkComp.MaxAttenuationRadius;
			// 	Print(Message, 0);
			// }
		}

		if (TextComp != nullptr) 
		{
			TextComp.HazeSetTextRenderColor(Color);
			ParentWorldLocation.Z += HeightOffset;
			if (ParentWorldLocation != TextComp.GetWorldLocation())
				TextComp.SetWorldLocation(ParentWorldLocation);
				
			auto Text = GetAttachParent().GetName() + EventNames + ListenerText;
			TextComp.SetText(FText::FromString(Text));
		}

	}
	
}


