<?xml version='1.0' encoding='UTF-8'?>
<Project Type="Project" LVVersion="18008000">
	<Property Name="CCSymbols" Type="Str"></Property>
	<Property Name="Instrument Driver" Type="Str">True</Property>
	<Property Name="NI.Project.Description" Type="Str">This project is used by developers to edit API and example files for LabVIEW Plug and Play instrument drivers.</Property>
	<Item Name="My Computer" Type="My Computer">
		<Property Name="CCSymbols" Type="Str">OS,Win;CPU,x86;</Property>
		<Property Name="NI.SortType" Type="Int">3</Property>
		<Property Name="specify.custom.address" Type="Bool">false</Property>
		<Item Name="KE26XX.lvlib" Type="Library" URL="/&lt;instrlib&gt;/KE26XX/KE26XX.lvlib"/>
		<Item Name="Dependencies" Type="Dependencies">
			<Item Name="vi.lib" Type="Folder">
				<Item Name="Error Cluster From Error Code.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Error Cluster From Error Code.vi"/>
				<Item Name="whitespace.ctl" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/whitespace.ctl"/>
				<Item Name="Trim Whitespace.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Trim Whitespace.vi"/>
				<Item Name="Merge Errors.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Merge Errors.vi"/>
			</Item>
		</Item>
		<Item Name="Build Specifications" Type="Build">
			<Item Name="KE26XX" Type="Source Distribution">
				<Property Name="Bld_buildCacheID" Type="Str">{6FDC23C1-52D9-4DBC-890C-97568F3E0A7A}</Property>
				<Property Name="Bld_buildSpecName" Type="Str">KE26XX</Property>
				<Property Name="Bld_excludedDirectory[0]" Type="Path">vi.lib</Property>
				<Property Name="Bld_excludedDirectory[0].pathType" Type="Str">relativeToAppDir</Property>
				<Property Name="Bld_excludedDirectory[1]" Type="Path">..</Property>
				<Property Name="Bld_excludedDirectory[1].pathType" Type="Str">relativeToCommon</Property>
				<Property Name="Bld_excludedDirectory[2]" Type="Path">user.lib</Property>
				<Property Name="Bld_excludedDirectory[2].pathType" Type="Str">relativeToAppDir</Property>
				<Property Name="Bld_excludedDirectoryCount" Type="Int">3</Property>
				<Property Name="Bld_excludeTypedefs" Type="Bool">true</Property>
				<Property Name="Bld_localDestDir" Type="Path">../builds/NI_AB_PROJECTNAME/KE26XX.llb</Property>
				<Property Name="Bld_localDestDirType" Type="Str">relativeToCommon</Property>
				<Property Name="Bld_previewCacheID" Type="Str">{65D70933-9264-4C60-8D4F-2AD0ACFCA229}</Property>
				<Property Name="Bld_targetDestDir" Type="Path"></Property>
				<Property Name="Bld_version.major" Type="Int">1</Property>
				<Property Name="Destination[0].destName" Type="Str">Destination Directory</Property>
				<Property Name="Destination[0].path" Type="Path">../builds/NI_AB_PROJECTNAME/KE26XX.llb</Property>
				<Property Name="Destination[0].type" Type="Str">LLB</Property>
				<Property Name="Destination[1].destName" Type="Str">Support Directory</Property>
				<Property Name="Destination[1].path" Type="Path">../builds/NI_AB_PROJECTNAME</Property>
				<Property Name="DestinationCount" Type="Int">2</Property>
				<Property Name="Source[0].itemID" Type="Str">{B55B041E-1FE3-46D5-9FBF-619A4C177DC6}</Property>
				<Property Name="Source[0].type" Type="Str">Container</Property>
				<Property Name="Source[1].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[1].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Action-Status/Error Queue/Error Queue Clear.vi</Property>
				<Property Name="Source[1].type" Type="Str">VI</Property>
				<Property Name="Source[10].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[10].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Action-Status/Status Model/SRE Mask.vi</Property>
				<Property Name="Source[10].type" Type="Str">VI</Property>
				<Property Name="Source[100].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[100].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Examples/Real Converter Usage.vi</Property>
				<Property Name="Source[100].type" Type="Str">VI</Property>
				<Property Name="Source[101].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[101].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/dir.mnu</Property>
				<Property Name="Source[102].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[102].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Close.vi</Property>
				<Property Name="Source[102].type" Type="Str">VI</Property>
				<Property Name="Source[103].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[103].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Initialize.vi</Property>
				<Property Name="Source[103].type" Type="Str">VI</Property>
				<Property Name="Source[104].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[104].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/VI Tree.vi</Property>
				<Property Name="Source[104].type" Type="Str">VI</Property>
				<Property Name="Source[104].VI.LLBtopLevel" Type="Bool">true</Property>
				<Property Name="Source[105].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[105].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Private/Default Instrument Setup.vi</Property>
				<Property Name="Source[105].type" Type="Str">VI</Property>
				<Property Name="Source[106].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[106].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Private/GlobalVariables.vi</Property>
				<Property Name="Source[106].type" Type="Str">VI</Property>
				<Property Name="Source[107].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[107].itemID" Type="Ref">/My Computer/KE26XX.lvlib/KE26XX Readme.html</Property>
				<Property Name="Source[107].sourceInclusion" Type="Str">Include</Property>
				<Property Name="Source[108].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[108].itemID" Type="Ref">/My Computer/KE26XX.lvlib</Property>
				<Property Name="Source[108].Library.allowMissingMembers" Type="Bool">true</Property>
				<Property Name="Source[108].sourceInclusion" Type="Str">Include</Property>
				<Property Name="Source[108].type" Type="Str">Library</Property>
				<Property Name="Source[109].Container.applyInclusion" Type="Bool">true</Property>
				<Property Name="Source[109].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[109].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public</Property>
				<Property Name="Source[109].sourceInclusion" Type="Str">Include</Property>
				<Property Name="Source[109].type" Type="Str">Container</Property>
				<Property Name="Source[11].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[11].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Action-Status/Status Model/SRE.vi</Property>
				<Property Name="Source[11].type" Type="Str">VI</Property>
				<Property Name="Source[110].Container.applyInclusion" Type="Bool">true</Property>
				<Property Name="Source[110].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[110].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Private</Property>
				<Property Name="Source[110].sourceInclusion" Type="Str">Include</Property>
				<Property Name="Source[110].type" Type="Str">Container</Property>
				<Property Name="Source[12].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[12].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Action-Status/Status Model/STB.vi</Property>
				<Property Name="Source[12].type" Type="Str">VI</Property>
				<Property Name="Source[13].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[13].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Action-Status/Status Model/TST.vi</Property>
				<Property Name="Source[13].type" Type="Str">VI</Property>
				<Property Name="Source[14].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[14].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Action-Status/TSP-Link/TSP-Link Execute.vi</Property>
				<Property Name="Source[14].type" Type="Str">VI</Property>
				<Property Name="Source[15].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[15].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Action-Status/TSP-Link/TSP-Link Get Global.vi</Property>
				<Property Name="Source[15].type" Type="Str">VI</Property>
				<Property Name="Source[16].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[16].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Action-Status/TSP-Link/TSP-Link Group.vi</Property>
				<Property Name="Source[16].type" Type="Str">VI</Property>
				<Property Name="Source[17].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[17].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Action-Status/TSP-Link/TSP-Link Reset.vi</Property>
				<Property Name="Source[17].type" Type="Str">VI</Property>
				<Property Name="Source[18].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[18].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Action-Status/TSP-Link/TSP-Link Set Global.vi</Property>
				<Property Name="Source[18].type" Type="Str">VI</Property>
				<Property Name="Source[19].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[19].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Action-Status/TSP-Link/TSP-Link Set Node Number.vi</Property>
				<Property Name="Source[19].type" Type="Str">VI</Property>
				<Property Name="Source[2].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[2].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Action-Status/Error Queue/Error Queue Count.vi</Property>
				<Property Name="Source[2].type" Type="Str">VI</Property>
				<Property Name="Source[20].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[20].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Action-Status/TSP-Link/TSP-Link State.vi</Property>
				<Property Name="Source[20].type" Type="Str">VI</Property>
				<Property Name="Source[21].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[21].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Action-Status/Action-Status.mnu</Property>
				<Property Name="Source[22].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[22].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Measure/Measure Autorange.vi</Property>
				<Property Name="Source[22].type" Type="Str">VI</Property>
				<Property Name="Source[23].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[23].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Measure/Measure Autozero.vi</Property>
				<Property Name="Source[23].type" Type="Str">VI</Property>
				<Property Name="Source[24].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[24].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Measure/Measure Count.vi</Property>
				<Property Name="Source[24].type" Type="Str">VI</Property>
				<Property Name="Source[25].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[25].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Measure/Measure Filter Count.vi</Property>
				<Property Name="Source[25].type" Type="Str">VI</Property>
				<Property Name="Source[26].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[26].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Measure/Measure Filter Enable.vi</Property>
				<Property Name="Source[26].type" Type="Str">VI</Property>
				<Property Name="Source[27].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[27].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Measure/Measure FilterType.vi</Property>
				<Property Name="Source[27].type" Type="Str">VI</Property>
				<Property Name="Source[28].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[28].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Measure/Measure Interval.vi</Property>
				<Property Name="Source[28].type" Type="Str">VI</Property>
				<Property Name="Source[29].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[29].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Measure/Measure Lowrange.vi</Property>
				<Property Name="Source[29].type" Type="Str">VI</Property>
				<Property Name="Source[3].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[3].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Action-Status/Error Queue/Error Queue Next.vi</Property>
				<Property Name="Source[3].type" Type="Str">VI</Property>
				<Property Name="Source[30].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[30].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Measure/Measure NPLC.vi</Property>
				<Property Name="Source[30].type" Type="Str">VI</Property>
				<Property Name="Source[31].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[31].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Measure/Measure Range.vi</Property>
				<Property Name="Source[31].type" Type="Str">VI</Property>
				<Property Name="Source[32].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[32].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Measure/Measure Relative Enable.vi</Property>
				<Property Name="Source[32].type" Type="Str">VI</Property>
				<Property Name="Source[33].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[33].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Measure/Measure Relative Level.vi</Property>
				<Property Name="Source[33].type" Type="Str">VI</Property>
				<Property Name="Source[34].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[34].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Measure/Measure Sense Mode.vi</Property>
				<Property Name="Source[34].type" Type="Str">VI</Property>
				<Property Name="Source[35].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[35].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Source/Source Autorange.vi</Property>
				<Property Name="Source[35].type" Type="Str">VI</Property>
				<Property Name="Source[36].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[36].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Source/Source Compliance Query.vi</Property>
				<Property Name="Source[36].type" Type="Str">VI</Property>
				<Property Name="Source[37].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[37].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Source/Source Function.vi</Property>
				<Property Name="Source[37].type" Type="Str">VI</Property>
				<Property Name="Source[38].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[38].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Source/Source Level.vi</Property>
				<Property Name="Source[38].type" Type="Str">VI</Property>
				<Property Name="Source[39].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[39].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Source/Source Limit.vi</Property>
				<Property Name="Source[39].type" Type="Str">VI</Property>
				<Property Name="Source[4].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[4].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Action-Status/Error Queue/Show Errors.vi</Property>
				<Property Name="Source[4].type" Type="Str">VI</Property>
				<Property Name="Source[40].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[40].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Source/Source Lowrange.vi</Property>
				<Property Name="Source[40].type" Type="Str">VI</Property>
				<Property Name="Source[41].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[41].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Source/Source Off Mode.vi</Property>
				<Property Name="Source[41].type" Type="Str">VI</Property>
				<Property Name="Source[42].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[42].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Source/Source Range.vi</Property>
				<Property Name="Source[42].type" Type="Str">VI</Property>
				<Property Name="Source[43].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[43].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Config Measure Filter.vi</Property>
				<Property Name="Source[43].type" Type="Str">VI</Property>
				<Property Name="Source[44].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[44].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Config Measure Function.vi</Property>
				<Property Name="Source[44].type" Type="Str">VI</Property>
				<Property Name="Source[45].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[45].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Config Measure Settings.vi</Property>
				<Property Name="Source[45].type" Type="Str">VI</Property>
				<Property Name="Source[46].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[46].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Config Source.vi</Property>
				<Property Name="Source[46].type" Type="Str">VI</Property>
				<Property Name="Source[47].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[47].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Action-Status/Source Output Enable.vi</Property>
				<Property Name="Source[47].type" Type="Str">VI</Property>
				<Property Name="Source[48].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[48].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Configure/Configure.mnu</Property>
				<Property Name="Source[49].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[49].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Data/Reading Buffers/Buffer Base Timestamp.vi</Property>
				<Property Name="Source[49].type" Type="Str">VI</Property>
				<Property Name="Source[5].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[5].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Action-Status/Status Model/CLS.vi</Property>
				<Property Name="Source[5].type" Type="Str">VI</Property>
				<Property Name="Source[50].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[50].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Data/Reading Buffers/Buffer Capacity.vi</Property>
				<Property Name="Source[50].type" Type="Str">VI</Property>
				<Property Name="Source[51].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[51].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Data/Reading Buffers/Buffer Clear.vi</Property>
				<Property Name="Source[51].type" Type="Str">VI</Property>
				<Property Name="Source[52].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[52].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Data/Reading Buffers/Buffer Configure.vi</Property>
				<Property Name="Source[52].type" Type="Str">VI</Property>
				<Property Name="Source[53].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[53].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Data/Reading Buffers/Buffer Make Buffer.vi</Property>
				<Property Name="Source[53].type" Type="Str">VI</Property>
				<Property Name="Source[54].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[54].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Data/Reading Buffers/Buffer Num Readings.vi</Property>
				<Property Name="Source[54].type" Type="Str">VI</Property>
				<Property Name="Source[55].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[55].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Data/Measure in Background.vi</Property>
				<Property Name="Source[55].type" Type="Str">VI</Property>
				<Property Name="Source[56].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[56].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Data/Measure then Step Source.vi</Property>
				<Property Name="Source[56].type" Type="Str">VI</Property>
				<Property Name="Source[57].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[57].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Data/Measure.vi</Property>
				<Property Name="Source[57].type" Type="Str">VI</Property>
				<Property Name="Source[58].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[58].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Data/Data.mnu</Property>
				<Property Name="Source[59].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[59].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Digital IO/Digio Read Bit.vi</Property>
				<Property Name="Source[59].type" Type="Str">VI</Property>
				<Property Name="Source[6].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[6].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Action-Status/Status Model/ESE Mask.vi</Property>
				<Property Name="Source[6].type" Type="Str">VI</Property>
				<Property Name="Source[60].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[60].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Digital IO/Digio Read Port.vi</Property>
				<Property Name="Source[60].type" Type="Str">VI</Property>
				<Property Name="Source[61].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[61].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Digital IO/Digio Trigger Assert.vi</Property>
				<Property Name="Source[61].type" Type="Str">VI</Property>
				<Property Name="Source[62].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[62].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Digital IO/Digio Trigger Config.vi</Property>
				<Property Name="Source[62].type" Type="Str">VI</Property>
				<Property Name="Source[63].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[63].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Digital IO/Digio Trigger Release.vi</Property>
				<Property Name="Source[63].type" Type="Str">VI</Property>
				<Property Name="Source[64].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[64].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Digital IO/Digio Write Bit.vi</Property>
				<Property Name="Source[64].type" Type="Str">VI</Property>
				<Property Name="Source[65].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[65].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Digital IO/Digio Write Port.vi</Property>
				<Property Name="Source[65].type" Type="Str">VI</Property>
				<Property Name="Source[66].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[66].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Digital IO/Digio Write Protect.vi</Property>
				<Property Name="Source[66].type" Type="Str">VI</Property>
				<Property Name="Source[67].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[67].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Display/Display Digits.vi</Property>
				<Property Name="Source[67].type" Type="Str">VI</Property>
				<Property Name="Source[68].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[68].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Display/Display Load Menu Add.vi</Property>
				<Property Name="Source[68].type" Type="Str">VI</Property>
				<Property Name="Source[69].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[69].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Display/Display Load Menu Delete.vi</Property>
				<Property Name="Source[69].type" Type="Str">VI</Property>
				<Property Name="Source[7].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[7].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Action-Status/Status Model/ESE.vi</Property>
				<Property Name="Source[7].type" Type="Str">VI</Property>
				<Property Name="Source[70].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[70].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Display/Display Measure Function.vi</Property>
				<Property Name="Source[70].type" Type="Str">VI</Property>
				<Property Name="Source[71].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[71].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Display/Display Screen.vi</Property>
				<Property Name="Source[71].type" Type="Str">VI</Property>
				<Property Name="Source[72].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[72].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Factory Pulse/Config Pulse I Measure V Sweep.vi</Property>
				<Property Name="Source[72].type" Type="Str">VI</Property>
				<Property Name="Source[73].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[73].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Factory Pulse/Config Pulse I Measure V.vi</Property>
				<Property Name="Source[73].type" Type="Str">VI</Property>
				<Property Name="Source[74].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[74].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Factory Pulse/Config Pulse V Measure I Sweep.vi</Property>
				<Property Name="Source[74].type" Type="Str">VI</Property>
				<Property Name="Source[75].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[75].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Factory Pulse/Config Pulse V Measure I.vi</Property>
				<Property Name="Source[75].type" Type="Str">VI</Property>
				<Property Name="Source[76].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[76].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Factory Pulse/Initiate Pulse Test Dual.vi</Property>
				<Property Name="Source[76].type" Type="Str">VI</Property>
				<Property Name="Source[77].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[77].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Factory Pulse/Initiate Pulse Test.vi</Property>
				<Property Name="Source[77].type" Type="Str">VI</Property>
				<Property Name="Source[78].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[78].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Scripting/Delete Script.vi</Property>
				<Property Name="Source[78].type" Type="Str">VI</Property>
				<Property Name="Source[79].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[79].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Scripting/List Non-Volatile User Scripts.vi</Property>
				<Property Name="Source[79].type" Type="Str">VI</Property>
				<Property Name="Source[8].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[8].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Action-Status/Status Model/ESR.vi</Property>
				<Property Name="Source[8].type" Type="Str">VI</Property>
				<Property Name="Source[80].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[80].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Scripting/Load Script.vi</Property>
				<Property Name="Source[80].type" Type="Str">VI</Property>
				<Property Name="Source[81].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[81].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Serial Port/Serial Port Configure.vi</Property>
				<Property Name="Source[81].type" Type="Str">VI</Property>
				<Property Name="Source[82].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[82].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Serial Port/Serial Read.vi</Property>
				<Property Name="Source[82].type" Type="Str">VI</Property>
				<Property Name="Source[83].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[83].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Serial Port/Serial Write.vi</Property>
				<Property Name="Source[83].type" Type="Str">VI</Property>
				<Property Name="Source[84].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[84].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Data Output Format.vi</Property>
				<Property Name="Source[84].type" Type="Str">VI</Property>
				<Property Name="Source[85].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[85].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Error Query.vi</Property>
				<Property Name="Source[85].type" Type="Str">VI</Property>
				<Property Name="Source[86].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[86].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Node Format.vi</Property>
				<Property Name="Source[86].type" Type="Str">VI</Property>
				<Property Name="Source[87].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[87].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Print Buffer.vi</Property>
				<Property Name="Source[87].type" Type="Str">VI</Property>
				<Property Name="Source[88].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[88].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Print Number.vi</Property>
				<Property Name="Source[88].type" Type="Str">VI</Property>
				<Property Name="Source[89].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[89].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Print.vi</Property>
				<Property Name="Source[89].type" Type="Str">VI</Property>
				<Property Name="Source[9].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[9].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Action-Status/Status Model/OPC.vi</Property>
				<Property Name="Source[9].type" Type="Str">VI</Property>
				<Property Name="Source[90].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[90].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Real 32 Converter.vi</Property>
				<Property Name="Source[90].type" Type="Str">VI</Property>
				<Property Name="Source[91].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[91].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Real 64 Converter.vi</Property>
				<Property Name="Source[91].type" Type="Str">VI</Property>
				<Property Name="Source[92].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[92].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Reset SMU.vi</Property>
				<Property Name="Source[92].type" Type="Str">VI</Property>
				<Property Name="Source[93].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[93].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Reset.vi</Property>
				<Property Name="Source[93].type" Type="Str">VI</Property>
				<Property Name="Source[94].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[94].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Revision Query.vi</Property>
				<Property Name="Source[94].type" Type="Str">VI</Property>
				<Property Name="Source[95].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[95].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Self-Test.vi</Property>
				<Property Name="Source[95].type" Type="Str">VI</Property>
				<Property Name="Source[96].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[96].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Utility/Utility.mnu</Property>
				<Property Name="Source[97].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[97].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Examples/Config Source &amp; Measure.vi</Property>
				<Property Name="Source[97].type" Type="Str">VI</Property>
				<Property Name="Source[98].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[98].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Examples/Factory Pulse Usage.vi</Property>
				<Property Name="Source[98].type" Type="Str">VI</Property>
				<Property Name="Source[99].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[99].itemID" Type="Ref">/My Computer/KE26XX.lvlib/Public/Examples/Factory Pulse Script Usage.vi</Property>
				<Property Name="Source[99].type" Type="Str">VI</Property>
				<Property Name="SourceCount" Type="Int">111</Property>
			</Item>
		</Item>
	</Item>
</Project>
