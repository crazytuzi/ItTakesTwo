import Vino.Audio.PhysMaterials.PhysicalMaterialAudio;

class UPopulatePhysAudioAssetActionUtility : UAssetActionUtility
{
	UFUNCTION(BlueprintOverride)
	UClass GetSupportedClass() const
	{
		return UPhysicalMaterialAudio::StaticClass();
	}

	UFUNCTION(CallInEditor, Category = "Haze Menu")
	void PopulatePhysAudioAsset()
	{
		for (UObject AssetObj : EditorUtility::GetSelectedAssets())
		{
			UPhysicalMaterialAudio PhysMaterialAudio = Cast<UPhysicalMaterialAudio>(AssetObj);
			if (PhysMaterialAudio != nullptr)
			{
				bool bModified = false;
				
				FHazeReturnAudioMaterialEvents OutCodyEvents;
				FHazeReturnAudioMaterialEvents OutMayEvents;
				
				// Get all related events to any of the set footstep events
				if (PhysMaterialAudio.CodyMaterialEvents.CodyMaterialFootstepEvent != nullptr)
				{
					Editor::GetAllRelatedPhysAudioMaterialEvents(PhysMaterialAudio.CodyMaterialEvents.CodyMaterialFootstepEvent, OutCodyEvents, OutMayEvents);
				}
				else if (PhysMaterialAudio.MayMaterialEvents.MayMaterialFootstepEvent != nullptr)
				{
					Editor::GetAllRelatedPhysAudioMaterialEvents(PhysMaterialAudio.MayMaterialEvents.MayMaterialFootstepEvent, OutCodyEvents, OutMayEvents);
				}

				// Set Cody Events
				if (OutCodyEvents.MaterialFootstepEvent != nullptr && OutCodyEvents.MaterialFootstepEvent != PhysMaterialAudio.CodyMaterialEvents.CodyMaterialFootstepEvent)
				{
					PhysMaterialAudio.CodyMaterialEvents.CodyMaterialFootstepEvent = OutCodyEvents.MaterialFootstepEvent;
					bModified = true;
				}
				if (OutCodyEvents.MaterialScuffEvent != nullptr && OutCodyEvents.MaterialScuffEvent != PhysMaterialAudio.CodyMaterialEvents.CodyMaterialScuffEvent)
				{
					PhysMaterialAudio.CodyMaterialEvents.CodyMaterialScuffEvent = OutCodyEvents.MaterialScuffEvent;
					bModified = true;
				}
				if (OutCodyEvents.MaterialHandEvent != nullptr && OutCodyEvents.MaterialHandEvent != PhysMaterialAudio.CodyMaterialEvents.CodyMaterialHandEvent)
				{
					PhysMaterialAudio.CodyMaterialEvents.CodyMaterialHandEvent = OutCodyEvents.MaterialHandEvent;
					bModified = true;
				}
				if (OutCodyEvents.MaterialHandScuffEvent != nullptr && OutCodyEvents.MaterialHandScuffEvent != PhysMaterialAudio.CodyMaterialEvents.CodyMaterialHandScuffEvent)
				{
					PhysMaterialAudio.CodyMaterialEvents.CodyMaterialHandScuffEvent = OutCodyEvents.MaterialHandScuffEvent;
					bModified = true;
				}
				if (OutCodyEvents.MaterialLandEvent != nullptr && OutCodyEvents.MaterialLandEvent != PhysMaterialAudio.CodyMaterialEvents.CodyMaterialLandEvent)
				{
					PhysMaterialAudio.CodyMaterialEvents.CodyMaterialLandEvent = OutCodyEvents.MaterialLandEvent;
					bModified = true;
				}
				if (OutCodyEvents.MaterialFootSlideEvent != nullptr && OutCodyEvents.MaterialFootSlideEvent != PhysMaterialAudio.CodyMaterialEvents.CodyMaterialFootSlideEvent)
				{
					PhysMaterialAudio.CodyMaterialEvents.CodyMaterialFootSlideEvent = OutCodyEvents.MaterialFootSlideEvent;
					bModified = true;
				}
				if (OutCodyEvents.MaterialHandSlideEvent != nullptr && OutCodyEvents.MaterialHandSlideEvent != PhysMaterialAudio.CodyMaterialEvents.CodyMaterialHandSlideEvent)
				{
					PhysMaterialAudio.CodyMaterialEvents.CodyMaterialHandSlideEvent = OutCodyEvents.MaterialHandSlideEvent;
					bModified = true;
				}
				if (OutCodyEvents.MaterialAssSlideEvent != nullptr && OutCodyEvents.MaterialAssSlideEvent != PhysMaterialAudio.CodyMaterialEvents.CodyMaterialAssSlideEvent)
				{
					PhysMaterialAudio.CodyMaterialEvents.CodyMaterialAssSlideEvent = OutCodyEvents.MaterialAssSlideEvent;
					bModified = true;
				}

				// Set May Events
				if (OutMayEvents.MaterialFootstepEvent != nullptr && OutMayEvents.MaterialFootstepEvent != PhysMaterialAudio.MayMaterialEvents.MayMaterialFootstepEvent)
				{
					PhysMaterialAudio.MayMaterialEvents.MayMaterialFootstepEvent = OutMayEvents.MaterialFootstepEvent;
					bModified = true;
				}
				if (OutMayEvents.MaterialScuffEvent != nullptr && OutMayEvents.MaterialScuffEvent != PhysMaterialAudio.MayMaterialEvents.MayMaterialScuffEvent)
				{
					PhysMaterialAudio.MayMaterialEvents.MayMaterialScuffEvent = OutMayEvents.MaterialScuffEvent;
					bModified = true;
				}
				if (OutMayEvents.MaterialHandEvent != nullptr && OutMayEvents.MaterialHandEvent != PhysMaterialAudio.MayMaterialEvents.MayMaterialHandEvent)
				{
					PhysMaterialAudio.MayMaterialEvents.MayMaterialHandEvent = OutMayEvents.MaterialHandEvent;
					bModified = true;
				}
				if (OutMayEvents.MaterialHandScuffEvent != nullptr && OutMayEvents.MaterialHandScuffEvent != PhysMaterialAudio.MayMaterialEvents.MayMaterialHandScuffEvent)
				{
					PhysMaterialAudio.MayMaterialEvents.MayMaterialHandScuffEvent = OutMayEvents.MaterialHandScuffEvent;
					bModified = true;
				}
				if (OutMayEvents.MaterialLandEvent != nullptr && OutMayEvents.MaterialLandEvent != PhysMaterialAudio.MayMaterialEvents.MayMaterialLandEvent)
				{
					PhysMaterialAudio.MayMaterialEvents.MayMaterialLandEvent = OutMayEvents.MaterialLandEvent;
					bModified = true;
				}
				if (OutMayEvents.MaterialFootSlideEvent != nullptr && OutMayEvents.MaterialFootSlideEvent != PhysMaterialAudio.MayMaterialEvents.MayMaterialFootSlideEvent)
				{
					PhysMaterialAudio.MayMaterialEvents.MayMaterialFootSlideEvent = OutMayEvents.MaterialFootSlideEvent;
					bModified = true;
				}
				if (OutMayEvents.MaterialHandSlideEvent != nullptr && OutMayEvents.MaterialHandSlideEvent != PhysMaterialAudio.MayMaterialEvents.MayMaterialHandSlideEvent)
				{
					PhysMaterialAudio.MayMaterialEvents.MayMaterialHandSlideEvent = OutMayEvents.MaterialHandSlideEvent;
					bModified = true;
				}
				if (OutMayEvents.MaterialAssSlideEvent != nullptr && OutMayEvents.MaterialAssSlideEvent != PhysMaterialAudio.MayMaterialEvents.MayMaterialAssSlideEvent)
				{
					PhysMaterialAudio.MayMaterialEvents.MayMaterialAssSlideEvent = OutMayEvents.MaterialAssSlideEvent;
					bModified = true;
				}

				// Mark dirty if anything was changed
				if (bModified)
					PhysMaterialAudio.Modify();
			}
		}
	}
};