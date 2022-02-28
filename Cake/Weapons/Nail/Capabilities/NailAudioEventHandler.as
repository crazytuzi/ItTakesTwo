
import Cake.Weapons.Nail.Capabilities.NailEventHandler;
import Peanuts.Audio.AudioStatics;
import Peanuts.Audio.HazeAudioEffects.DopplerEffect;
import Vino.Audio.PhysMaterials.PhysicalMaterialAudio;

UCLASS()
class UNailAudioEventHandler : UNailEventHandler 
{
	default CapabilityTags.Add(n"NailAudio");

	FString LastImpactSwitch = "";
	
	UPROPERTY()
	UDopplerEffect ProjectileDoppler;

	UHazeAkComponent HazeAkComp;

	float LastNailVelocityValue;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Nail = Cast<ANailWeaponActor>(Owner);
		HazeAkComp = Nail.HazeAkComp;

		ProjectileDoppler = Cast<UDopplerEffect>(HazeAkComp.AddEffect(UDopplerEffect::StaticClass()));
		ProjectileDoppler.SetObjectDopplerValues(true, Observer = EHazeDopplerObserverType::May);
		ProjectileDoppler.PlayPassbySound(Nail.PassbyEvent, 0.1f, 0.1f, VelocityAngle = 0.5f);
		ProjectileDoppler.SetEnabled(false);		
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Call super to ensure our parents OnActivated() is called as well.
		Super::OnActivated(ActivationParams);		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Call super to ensure that the parents function is called as well. 
		Super::OnDeactivated(DeactivationParams);

		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaTime)
	{
		//Print(""+Nail.GetNailVelocity().Size(), 1.f);
		float Velocity = Nail.GetNailVelocity().Size();
		float VelocityScaled = HazeAudio::NormalizeRTPC(Velocity, 250.f, 50000.f, 0.f, 1.f);	

		if(Velocity != LastNailVelocityValue)
		{
			HazeAkComp.SetRTPCValue("Rtpc_Gadget_Nail_Velocity", VelocityScaled, 0.f);		
			LastNailVelocityValue = Velocity;
		}

		const float NailVelocity = Nail.GetNailVelocity().Size() / Nail.MovementComponent.CollisionVelocity;

		// Print(Nail.GetName() + " NailVelocity: " + NailVelocity, 0.f);

		HazeAkComp.SetRTPCValue("Rtpc_Gadget_Nail_CollisionVelocity", NailVelocity, 0.f);

		//Print(""+NailVelocity, 0.1f);
	}

	UFUNCTION(BlueprintOverride)
	void HandleNailRecallCollisionEnter(const float TravelTimeRemaining, FHitResult HitData) 
	{
		// const float Duration = 5.f;
		// System::DrawDebugSphere(HitData.ImpactPoint, 50.f, 16, FLinearColor::Red, Duration);
		// System::DrawDebugPoint(HitData.ImpactPoint, 10.f, FLinearColor::Yellow, Duration);
	}

	UFUNCTION(BlueprintOverride)
	void HandleNailRecallCollisionExit(const float TravelTimeRemaining, FHitResult HitData) 
	{
		// const float Duration = 5.f;
		// System::DrawDebugSphere(HitData.ImpactPoint, 50.f, 16, FLinearColor::Green, Duration);
		// System::DrawDebugPoint(HitData.ImpactPoint, 10.f, FLinearColor::Yellow, Duration);
	}

	UFUNCTION(BlueprintOverride)
	void HandleNailPreCaught() 
	{
		HazeAkComp.HazePostEvent(Nail.CatchEvent);
		HazeAkComp.HazePostEvent(Nail.StopFlyingEvent);

		if(ProjectileDoppler != nullptr)
		{
			ProjectileDoppler.SetEnabled(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void HandleNailPostCaught() {}

	UFUNCTION(BlueprintOverride)
	void HandleNailThrown() 
	{
		//Print("NailThrow", Duration = 3.f);

		HazeAkComp.HazePostEvent(Nail.ThrowEvent);
		HazeAkComp.HazePostEvent(Nail.StartFlyingEvent);

		if(ProjectileDoppler != nullptr)
		{
			ProjectileDoppler.SetEnabled(true);
		}

	}

	UFUNCTION(BlueprintOverride)
	void HandleWiggleStarted() 
	{
		//Print("WiggleStart", Duration = 1.f);

		HazeAkComp.HazePostEvent(Nail.WiggleStartEvent);
	}

	UFUNCTION(BlueprintOverride)
	void HandleWiggleEnded() 
	{
		//Print("WiggleStop", Duration = 1.f);

		HazeAkComp.HazePostEvent(Nail.WiggleStopEvent);
	}

	UFUNCTION(BlueprintOverride)
	void HandleNailRecalled(const float EstimatedTravelTime) 
	{
		//Print("Recall", Duration = 3.f);

		HazeAkComp.HazePostEvent(Nail.RecallEvent);
		
		//Print("EsstTimeTravel"+EstimatedTravelTime, 1.f);

		HazeAkComp.SetRTPCValue("Rtpc_Gadget_Nail_TravelTimeEstimate", EstimatedTravelTime, 0.f);

		HazeAkComp.HazePostEvent(Nail.InComingEvent);

	}

	UFUNCTION(BlueprintOverride)
	void HandleNailUnpierced() 
	{
		//Print("UnPierced", Duration = 3.f);

		HazeAkComp.HazePostEvent(Nail.StartFlyingEvent);

		if(ProjectileDoppler != nullptr)
		{
			ProjectileDoppler.SetEnabled(true);
		}
	
	}

	UFUNCTION(BlueprintOverride)
	void HandleNailCollision(const FHitResult& HitData) 
	{
		// const float Duration = 5.f;
		// System::DrawDebugSphere(HitData.ImpactPoint, 50.f, 16, FLinearColor::Green, Duration);
		// System::DrawDebugPoint(HitData.ImpactPoint, 10.f, FLinearColor::Yellow, Duration);
		
		//Print(""+ HitData.GetPhysMaterial().SurfaceType , 1.f);

		HazeAkComp.HazePostEvent(Nail.StopFlyingEvent);
		UPhysicalMaterialAudio AudioMaterial = PhysicalMaterialAudio::GetPhysicalMaterialAudioAsset(HitData.Component);		

		if(AudioMaterial == nullptr)
			return;

		TArray<FString> SwitchData;
		AudioMaterial.GetMaterialSwitch(SwitchData);

		if(SwitchData.Num() == 2 && SwitchData[1] != LastImpactSwitch)
		{
			HazeAkComp.SetSwitch(SwitchData[0], SwitchData[1]);
			LastImpactSwitch = SwitchData[1];
		}

		HazeAkComp.HazePostEvent(Nail.MaterialImpactEvent);

	}

	UFUNCTION(BlueprintOverride)
	void HandleNailEquipped(AHazePlayerCharacter Wielder) {}

	UFUNCTION(BlueprintOverride)
	void HandleNailUnequipped(AHazePlayerCharacter Wielder) {}

	UFUNCTION(BlueprintOverride)
	void HandleNailDestroyed(AActor DestroyedActor) {}

	UFUNCTION(BlueprintOverride)
	void HandleNailPierced(
		AActor ActorDoingThePiercing,
		AActor ActorBeingPierced,
		UPrimitiveComponent ComponentBeingPierced,
		const FHitResult& HitResult) 
	{
		//Print("Pierced", Duration = 3.f);
		HazeAkComp.HazePostEvent(Nail.StickImpactEvent);
		HazeAkComp.HazePostEvent(Nail.StopFlyingEvent);

		if(ProjectileDoppler != nullptr)
		{
			ProjectileDoppler.SetEnabled(false);
		}

	}

}
