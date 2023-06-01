<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()> _
Partial Class Form1
    Inherits System.Windows.Forms.Form

    'Form overrides dispose to clean up the component list.
    <System.Diagnostics.DebuggerNonUserCode()> _
    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
        Try
            If disposing AndAlso components IsNot Nothing Then
                components.Dispose()
            End If
        Finally
            MyBase.Dispose(disposing)
        End Try
    End Sub

    'Required by the Windows Form Designer
    Private components As System.ComponentModel.IContainer

    'NOTE: The following procedure is required by the Windows Form Designer
    'It can be modified using the Windows Form Designer.  
    'Do not modify it using the code editor.
    <System.Diagnostics.DebuggerStepThrough()> _
    Private Sub InitializeComponent()
        Dim resources As System.ComponentModel.ComponentResourceManager = New System.ComponentModel.ComponentResourceManager(GetType(Form1))
        Me.cmdRun = New System.Windows.Forms.Button()
        Me.Label1 = New System.Windows.Forms.Label()
        Me.lstResults = New System.Windows.Forms.ListBox()
        Me.Label2 = New System.Windows.Forms.Label()
        Me.txtNPLC = New System.Windows.Forms.TextBox()
        Me.Label3 = New System.Windows.Forms.Label()
        Me.txtCurrent = New System.Windows.Forms.TextBox()
        Me.Label4 = New System.Windows.Forms.Label()
        Me.txtVLimit = New System.Windows.Forms.TextBox()
        Me.Label5 = New System.Windows.Forms.Label()
        Me.txt2181A_addr = New System.Windows.Forms.TextBox()
        Me.ShapeContainer1 = New Microsoft.VisualBasic.PowerPacks.ShapeContainer()
        Me.LineShape2 = New Microsoft.VisualBasic.PowerPacks.LineShape()
        Me.LineShape1 = New Microsoft.VisualBasic.PowerPacks.LineShape()
        Me.Label6 = New System.Windows.Forms.Label()
        Me.txt2450_addr = New System.Windows.Forms.TextBox()
        Me.lblHelp = New System.Windows.Forms.Label()
        Me.SuspendLayout()
        '
        'cmdRun
        '
        Me.cmdRun.Location = New System.Drawing.Point(383, 184)
        Me.cmdRun.Name = "cmdRun"
        Me.cmdRun.Size = New System.Drawing.Size(141, 30)
        Me.cmdRun.TabIndex = 0
        Me.cmdRun.Text = "Run"
        Me.cmdRun.UseVisualStyleBackColor = True
        '
        'Label1
        '
        Me.Label1.AutoSize = True
        Me.Label1.BackColor = System.Drawing.Color.Red
        Me.Label1.Font = New System.Drawing.Font("Microsoft Sans Serif", 9.75!, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.Label1.ForeColor = System.Drawing.SystemColors.ControlLightLight
        Me.Label1.Location = New System.Drawing.Point(46, 25)
        Me.Label1.Name = "Label1"
        Me.Label1.Size = New System.Drawing.Size(96, 16)
        Me.Label1.TabIndex = 1
        Me.Label1.Text = "  KEITHLEY  "
        '
        'lstResults
        '
        Me.lstResults.FormattingEnabled = True
        Me.lstResults.Location = New System.Drawing.Point(383, 64)
        Me.lstResults.Name = "lstResults"
        Me.lstResults.Size = New System.Drawing.Size(141, 95)
        Me.lstResults.TabIndex = 2
        '
        'Label2
        '
        Me.Label2.AutoSize = True
        Me.Label2.Location = New System.Drawing.Point(57, 124)
        Me.Label2.Name = "Label2"
        Me.Label2.Size = New System.Drawing.Size(69, 13)
        Me.Label2.TabIndex = 3
        Me.Label2.Text = "2182A NPLC"
        '
        'txtNPLC
        '
        Me.txtNPLC.Location = New System.Drawing.Point(172, 121)
        Me.txtNPLC.Name = "txtNPLC"
        Me.txtNPLC.Size = New System.Drawing.Size(41, 20)
        Me.txtNPLC.TabIndex = 4
        Me.txtNPLC.Text = "1"
        '
        'Label3
        '
        Me.Label3.AutoSize = True
        Me.Label3.Location = New System.Drawing.Point(58, 210)
        Me.Label3.Name = "Label3"
        Me.Label3.Size = New System.Drawing.Size(68, 13)
        Me.Label3.TabIndex = 5
        Me.Label3.Text = "2450 Current"
        '
        'txtCurrent
        '
        Me.txtCurrent.Location = New System.Drawing.Point(172, 207)
        Me.txtCurrent.Name = "txtCurrent"
        Me.txtCurrent.Size = New System.Drawing.Size(41, 20)
        Me.txtCurrent.TabIndex = 6
        Me.txtCurrent.Text = "0.1"
        '
        'Label4
        '
        Me.Label4.AutoSize = True
        Me.Label4.Location = New System.Drawing.Point(58, 235)
        Me.Label4.Name = "Label4"
        Me.Label4.Size = New System.Drawing.Size(94, 13)
        Me.Label4.TabIndex = 7
        Me.Label4.Text = "2450 Voltage Limit"
        '
        'txtVLimit
        '
        Me.txtVLimit.Location = New System.Drawing.Point(172, 235)
        Me.txtVLimit.Name = "txtVLimit"
        Me.txtVLimit.Size = New System.Drawing.Size(41, 20)
        Me.txtVLimit.TabIndex = 8
        Me.txtVLimit.Text = "2"
        '
        'Label5
        '
        Me.Label5.AutoSize = True
        Me.Label5.Location = New System.Drawing.Point(57, 93)
        Me.Label5.Name = "Label5"
        Me.Label5.Size = New System.Drawing.Size(91, 13)
        Me.Label5.TabIndex = 9
        Me.Label5.Text = "2182A GPIB Addr"
        '
        'txt2181A_addr
        '
        Me.txt2181A_addr.Location = New System.Drawing.Point(172, 90)
        Me.txt2181A_addr.Name = "txt2181A_addr"
        Me.txt2181A_addr.Size = New System.Drawing.Size(41, 20)
        Me.txt2181A_addr.TabIndex = 10
        Me.txt2181A_addr.Text = "7"
        '
        'ShapeContainer1
        '
        Me.ShapeContainer1.Location = New System.Drawing.Point(0, 0)
        Me.ShapeContainer1.Margin = New System.Windows.Forms.Padding(0)
        Me.ShapeContainer1.Name = "ShapeContainer1"
        Me.ShapeContainer1.Shapes.AddRange(New Microsoft.VisualBasic.PowerPacks.Shape() {Me.LineShape2, Me.LineShape1})
        Me.ShapeContainer1.Size = New System.Drawing.Size(601, 482)
        Me.ShapeContainer1.TabIndex = 11
        Me.ShapeContainer1.TabStop = False
        '
        'LineShape2
        '
        Me.LineShape2.Name = "LineShape2"
        Me.LineShape2.X1 = 44
        Me.LineShape2.X2 = 322
        Me.LineShape2.Y1 = 166
        Me.LineShape2.Y2 = 166
        '
        'LineShape1
        '
        Me.LineShape1.Name = "LineShape1"
        Me.LineShape1.X1 = 42
        Me.LineShape1.X2 = 320
        Me.LineShape1.Y1 = 81
        Me.LineShape1.Y2 = 81
        '
        'Label6
        '
        Me.Label6.AutoSize = True
        Me.Label6.Location = New System.Drawing.Point(57, 184)
        Me.Label6.Name = "Label6"
        Me.Label6.Size = New System.Drawing.Size(84, 13)
        Me.Label6.TabIndex = 12
        Me.Label6.Text = "2450 GPIB Addr"
        '
        'txt2450_addr
        '
        Me.txt2450_addr.Location = New System.Drawing.Point(172, 177)
        Me.txt2450_addr.Name = "txt2450_addr"
        Me.txt2450_addr.Size = New System.Drawing.Size(41, 20)
        Me.txt2450_addr.TabIndex = 13
        Me.txt2450_addr.Text = "18"
        '
        'lblHelp
        '
        Me.lblHelp.Location = New System.Drawing.Point(57, 331)
        Me.lblHelp.Name = "lblHelp"
        Me.lblHelp.Size = New System.Drawing.Size(487, 93)
        Me.lblHelp.TabIndex = 14
        Me.lblHelp.Text = resources.GetString("lblHelp.Text")
        '
        'Form1
        '
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.ClientSize = New System.Drawing.Size(601, 482)
        Me.Controls.Add(Me.lblHelp)
        Me.Controls.Add(Me.txt2450_addr)
        Me.Controls.Add(Me.Label6)
        Me.Controls.Add(Me.txt2181A_addr)
        Me.Controls.Add(Me.Label5)
        Me.Controls.Add(Me.txtVLimit)
        Me.Controls.Add(Me.Label4)
        Me.Controls.Add(Me.txtCurrent)
        Me.Controls.Add(Me.Label3)
        Me.Controls.Add(Me.txtNPLC)
        Me.Controls.Add(Me.Label2)
        Me.Controls.Add(Me.lstResults)
        Me.Controls.Add(Me.Label1)
        Me.Controls.Add(Me.cmdRun)
        Me.Controls.Add(Me.ShapeContainer1)
        Me.Name = "Form1"
        Me.Text = "Triggered Delta Mode Example:  2450 and 2182A"
        Me.ResumeLayout(False)
        Me.PerformLayout()

    End Sub
    Friend WithEvents cmdRun As System.Windows.Forms.Button
    Friend WithEvents Label1 As System.Windows.Forms.Label
    Friend WithEvents lstResults As System.Windows.Forms.ListBox
    Friend WithEvents Label2 As System.Windows.Forms.Label
    Friend WithEvents txtNPLC As System.Windows.Forms.TextBox
    Friend WithEvents Label3 As System.Windows.Forms.Label
    Friend WithEvents txtCurrent As System.Windows.Forms.TextBox
    Friend WithEvents Label4 As System.Windows.Forms.Label
    Friend WithEvents txtVLimit As System.Windows.Forms.TextBox
    Friend WithEvents Label5 As System.Windows.Forms.Label
    Friend WithEvents txt2181A_addr As System.Windows.Forms.TextBox
    Friend WithEvents ShapeContainer1 As Microsoft.VisualBasic.PowerPacks.ShapeContainer
    Friend WithEvents LineShape2 As Microsoft.VisualBasic.PowerPacks.LineShape
    Friend WithEvents LineShape1 As Microsoft.VisualBasic.PowerPacks.LineShape
    Friend WithEvents Label6 As System.Windows.Forms.Label
    Friend WithEvents txt2450_addr As System.Windows.Forms.TextBox
    Friend WithEvents lblHelp As System.Windows.Forms.Label

End Class
