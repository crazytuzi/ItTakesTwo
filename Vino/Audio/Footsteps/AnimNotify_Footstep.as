import Peanuts.Audio.AudioStatics;
import Vino.Audio.Footsteps.FootstepStatics;
import Vino.Audio.Movement.PlayerMovementAudioEventData;

#if TEST
import void SetFootstepDebugData(FFootstepTrace, FAudioPhysMaterial, bool) from "Cake.DebugMenus.Audio.AudioDebugManager";
#endif

UCLASS(NotBlueprintable, meta = ("FootstepAudio"))
class UAnimNotify_Footstep : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "FootstepAudio";
	}
	
	UPROPERTY(EditAnywhere, Category = "Parameters")
	FName FootstepTag;

	UPROPERTY(EditAnywhere, Category = "Parameters")
	UAkAudioEvent DefaultFootstepEvent;	

	UPROPERTY()
	HazeAudio::EPlayerFootstepType FootstepType;

	UPROPERTY()
	bool SpawnParticleEffect = true;

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		if (MeshComp.GetOwner() == nullptr)			
			return true;

		float MovementSpeed =  MeshComp.GetOwner().ActorVelocity.Size();
		FFootstepTrace Trace;

		auto HazeOwner = Cast<AHazeActor>(MeshComp.Owner);
		if (HazeOwner != nullptr)
		{			
			auto MoveComp = UHazeMovementComponent::Get(MeshComp.Owner);
			if (MoveComp != nullptr && !MoveComp.CanCalculateMovement())
			{
				// Extract what material we are standing on.
				GetFootstepTraceFromMovementComponent(MoveComp, Trace);
			}
			else
			{
				// We do not have any data on what we are standing on, trace to find out.
				FVector HipLoc = MeshComp.GetSocketLocation(n"Hips");
				// Extend from bounding box a bit to increase chans of hitting floor.
				float TraceDistance = MeshComp.BoundingBoxExtents.Z * 2.f;

				PerformFootstepTrace(
					HipLoc,
					HipLoc + HazeOwner.MovementWorldUp * -TraceDistance,
					Trace);
			}
		}
		else if(DefaultFootstepEvent != nullptr)
		{
			FOnAkPostEventCallback EventCallback = FOnAkPostEventCallback();
			AkGameplay::PostEvent(DefaultFootstepEvent, MeshComp.GetOwner(), 0);					
		}		

		AHazePlayerCharacter PlayerOwner = Cast<AHazePlayerCharacter>(HazeOwner);
		UPlayerMovementAudioComponent AudioMovementComp;		

		UPhysicalMaterialAudio AudioPhysMat = Trace.PhysAudio;
		UAkAudioEvent MaterialEvent;
		HazeAudio::EMaterialFootstepType SurfaceType = HazeAudio::EMaterialFootstepType::Soft;
		HazeAudio::EMaterialSlideType SlideType = HazeAudio::EMaterialSlideType::Rough;
		FAudioPhysMaterial AudioMaterial;
		

		if(PlayerOwner != nullptr)
		{
			AudioMovementComp = UPlayerMovementAudioComponent::Get(PlayerOwner);	
			if(AudioMovementComp.GrindingOverrideAudioPhysmat != nullptr)
				AudioPhysMat = AudioMovementComp.GrindingOverrideAudioPhysmat;
		}		

		if ((AudioMovementComp != nullptr && AudioMovementComp.OverrideFootstepEvent == nullptr) && AudioPhysMat != nullptr && PlayerOwner != nullptr)
		{
			AudioMaterial = AudioPhysMat.GetMaterialInteractionEvent(PlayerOwner, FootstepType);
			SurfaceType = AudioMaterial.MaterialType;
			SlideType = AudioMaterial.SlideType;
			MaterialEvent = AudioMaterial.AudioEvent;

			// Which foot is which is not marked, so for now pick random foot.
			bool foot = FMath::RandBool();
			FVector StepLocation 	= foot ? MeshComp.GetSocketLocation(n"LeftFoot") : MeshComp.GetSocketLocation(n"RightFoot");
			FRotator StepRotation 	= foot ? MeshComp.GetSocketRotation(n"LeftFoot") : MeshComp.GetSocketRotation(n"RightFoot");
			auto StepEffect = AudioPhysMat.GetMaterialEffectInteractionEvent(PlayerOwner, FootstepType);
			
			if(StepEffect != nullptr && SpawnParticleEffect)
			{
				Niagara::SpawnSystemAttached(StepEffect, PlayerOwner.RootComponent, NAME_None, StepLocation, StepRotation, EAttachLocation::KeepWorldPosition, true, true, ENCPoolMethod::AutoRelease);
			}
		}
		else if(AudioMovementComp != nullptr && AudioMovementComp.OverrideFootstepEvent != nullptr)
		{
			//A capability has given us a special override footstep, using this instead of a material one
			MaterialEvent = AudioMovementComp.OverrideFootstepEvent;
		} 		

		if (MaterialEvent == nullptr)
			MaterialEvent = DefaultFootstepEvent;

		UPlayerHazeAkComponent AkComp = UPlayerHazeAkComponent::Get(MeshComp.Owner, n"PlayerHazeAkComponent");

		#if TEST
		if (PlayerOwner != nullptr)
			SetFootstepDebugData(Trace, AudioMaterial, PlayerOwner.IsMay());
		#endif

		if (MaterialEvent != nullptr)
		{
			if(AkComp != nullptr)
			{
				AkComp.HazePostEvent(MaterialEvent, "", EHazeAudioPostEventType::Animation_Notify);
				//PrintScaled("Correct material footstep!", 0.5f, FLinearColor::Green, 2.f);
				//PrintScaled("" + Trace.PhysAudio.GetName(), 0.5f, FLinearColor::Black, 2.f);
				//PrintScaled("" + AudioMaterial.MaterialType, 0.5f, FLinearColor::Black, 2.f);
				//PrintScaled("" + AudioMaterial.SlideType, 0.5f, FLinearColor::Black, 2.f);
			}
		}
		else
		{
			//PrintScaled("Missing material footstep!", 0.5f, FLinearColor::Red, 2.f);
		}		
		
		if(AudioMovementComp != nullptr && AudioMovementComp.OverrideFootstepEvent == nullptr)
		{
			UAkAudioEvent PlayerDefaultFootstepEvent = AudioMovementComp.GetDefaultFootstepEvent(FootstepType, SurfaceType, SlideType);				

			if(PlayerDefaultFootstepEvent != nullptr)
			{
				AkComp.HazePostEvent(PlayerDefaultFootstepEvent,"", EHazeAudioPostEventType::Animation_Notify);
			}
		}
		#if EDITOR
		// (GK) - This is only for previewing
		else if (MeshComp.GetWorld().IsPreviewWorld())
		{
			TArray<FAssetData> OutAssets;
			if (AssetRegistry::GetAssetsByClass(FPlayerMovementAudioEventData::StaticClass().Name, OutAssets, false) &&
				OutAssets.Num() > 0)
			{
				for (FAssetData AssetData: OutAssets) 
				{
					if (AssetData.AssetName.ToString().Contains(MeshComp.SkeletalMesh.Name.ToString())) 
					{
						UObject Data = LoadObject(nullptr, AssetData.ObjectPath.ToString());
						if (Data != nullptr) 
						{
							FPlayerMovementAudioEventData EventData = Cast<FPlayerMovementAudioEventData>(Data);
							UAkAudioEvent PlayerDefaultFootstepEvent = EventData.GetDefaultFootstepEvent(FootstepType, SurfaceType, SlideType);
							if (PlayerDefaultFootstepEvent != nullptr) 
							{
								AkGameplay::PostEventOnDummyObject(PlayerDefaultFootstepEvent);
							}
						}
						break;
					}

				}
			}
		}
		#endif

		return true;
	}
};
